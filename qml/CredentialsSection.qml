import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

 GridView {
        id: grid
        property var columnWidth: app.width/model.count
        property var idealCellHeight: 76
        property var idealCellWidth: columnWidth > 300 ? columnWidth : 300
        anchors.fill: parent
        ScrollBar.vertical: ScrollBar {
            id: paneScrollBar
            width: 8
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            hoverEnabled: true
        }
        displayMarginBeginning: cellHeight
        onCurrentItemChanged: app.currentCredentialCard = currentItem
        keyNavigationWraps: false
        model: filteredCredentials()
        cellHeight: idealCellHeight
        cellWidth: width / Math.floor(width / idealCellWidth)
        Accessible.role: Accessible.MenuItem
        Accessible.focusable: true
        delegate: CredentialCard {
            credential: model.credential
            code: model.code
            // The delegate size is equal to the cell size...
            height: GridView.view.cellHeight
            width: GridView.view.cellWidth
            Rectangle {
                // ... but visible part is not. Here the width is set to the ideal size.
                // The visible part of the delegate is centered in the delegate, which means
                // the grid appears centered
                anchors.centerIn: parent
                width: parent.GridView.view ? parent.GridView.view.idealCellWidth : 0
                height: parent.height
            }
        }
        boundsBehavior: Flickable.StopAtBounds
        move: Transition {
            NumberAnimation { properties: "x,y"; duration: 250 }
        }
        focus: visible
        Component.onCompleted: currentIndex = -1
        KeyNavigation.backtab: toolBar.addCredentialBtn
        KeyNavigation.tab: toolBar.moreBtn
        KeyNavigation.up: paneScrollBar.position === 0 ? toolBar.searchField : null
        interactive: true
        highlightFollowsCurrentItem: true
        Keys.onEscapePressed: {
            toolBar.searchField.text = ""
            navigator.forceActiveFocus()
            currentIndex = -1
        }
        Keys.onSpacePressed: calculate()
        Keys.onEnterPressed: calculate()
        Keys.onReturnPressed: calculate()
        Keys.onDeletePressed: {
            if (currentIndex !== -1) {
                currentItem.deleteCard()
            }
        }
    }
