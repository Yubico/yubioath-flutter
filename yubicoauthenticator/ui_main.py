# Copyright (c) 2013-2014 Yubico AB
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Yubico GREEN #8cc041 Yubico RED #C04141

DEFAULT_STYLE = """
QProgressBar{
    border-radius: 1px;
    font-size: 15px;
    text-align: center
}

QProgressBar::chunk {
    background-color: #8cc041;
    width: 5px;
    margin: 0px;
}
"""

EXPIRE_STYLE = """
QProgressBar{
    border-radius: 1px;
    font-size: 15px;
    text-align: center
}

QProgressBar::chunk {
    background-color: #C04141;
    width: 5px;
    margin: 0px;
}
"""

import os
import sys
import time
import text
import ui_addaccount 
import commands as yc
import ui_password_change
import yubico_authenticator as gm



from PySide import QtCore, QtGui

YUBICO_ICON = "yubico.png"

class Ui_Dialog(object):
    def setupUi(self, Dialog):
        

        #FIX FOR PYINSTALLER
        if getattr(sys, 'frozen', False):
            # we are running in a PyInstaller bundle
            basedir = sys._MEIPASS
        else:
            # we are running in a normal Python environment
            basedir = os.path.dirname(__file__)

        Dialog.setObjectName("Dialog")
        Dialog.resize(311, 527)
        Dialog.setFixedSize(311, 527)
        self.gridLayoutWidget = QtGui.QWidget(Dialog)
        self.gridLayoutWidget.setGeometry(QtCore.QRect(10, 50, 291, 331))
        self.gridLayoutWidget.setObjectName("gridLayoutWidget")

        self.gridLayout = QtGui.QGridLayout(self.gridLayoutWidget)
        self.gridLayout.setContentsMargins(0, 0, 0, 0)
        self.gridLayout.setObjectName("gridLayout")
        self.gridLayout.setColumnStretch(1, 1)

        #left right cloumn in the grid layout
        self.leftList = QtGui.QListWidget(self.gridLayoutWidget)
        self.gridLayout.addWidget(self.leftList, 0, 0, 1, 1)
        self.rightList = QtGui.QListWidget(self.gridLayoutWidget)
        self.gridLayout.addWidget(self.rightList, 0, 1, 1, 1)
        #set the font for the qlistwidget
        listfont = QtGui.QFont()
        listfont.setPointSize(10)
        self.leftList.setFont(listfont)
        self.rightList.setFont(listfont)

        # action on click and double click for items in the list
        QtCore.QObject.connect(self.leftList, QtCore.SIGNAL("itemClicked(QListWidgetItem *)"), self.itemClicked)
        QtCore.QObject.connect(self.leftList, QtCore.SIGNAL("itemDoubleClicked(QListWidgetItem *)"), self.itemDoubleClicked)
        QtCore.QObject.connect(self.rightList, QtCore.SIGNAL("itemClicked(QListWidgetItem *)"), self.itemClicked)
        QtCore.QObject.connect(self.rightList, QtCore.SIGNAL("itemDoubleClicked(QListWidgetItem *)"), self.itemDoubleClicked)
 
        #timers
        # 1 - timer to update progress bar
        self.progress_timer = QtCore.QTimer()
        QtCore.QObject.connect(self.progress_timer, QtCore.SIGNAL("timeout()"), self.update_progressbar)
        self.progress_timer.start(1000)

        #set the progress bar
        self.progressBar = QtGui.QProgressBar(Dialog)
        self.progressBar.setGeometry(QtCore.QRect(10, 420, 231, 23))
        self.progressBar.setInputMethodHints(QtCore.Qt.ImhNone)
        self.progressBar.setMaximum(30)
        self.progressBar.setProperty("value", 30)
        self.progressBar.setInvertedAppearance(False)
        self.progressBar.setTextDirection(QtGui.QProgressBar.TopToBottom)
        self.progressBar.setObjectName("progressBar")

        #
        # Setting up all lables
        #
        self.label = QtGui.QLabel(Dialog)
        self.label.setGeometry(QtCore.QRect(243, 423, 51, 16))
        self.label.setObjectName("label")
        font = QtGui.QFont()
        font.setPointSize(8)
        self.label.setFont(font)


        self.label_2 = QtGui.QLabel(Dialog)
        self.label_2.setGeometry(QtCore.QRect(65, 15, 101, 41))
        font = QtGui.QFont()
        font.setFamily("Calibri")
        self.label_2.setFont(font)
        self.label_2.setObjectName("label_2")
        
        self.label_3 = QtGui.QLabel(Dialog)
        self.label_3.setGeometry(QtCore.QRect(180, 15, 161, 41))        
        font = QtGui.QFont()
        font.setFamily("Calibri")
        self.label_3.setFont(font)
        self.label_3.setWordWrap(True)
        self.label_3.setObjectName("label_3")
        
        self.label_4 = QtGui.QLabel(Dialog)
        self.label_4.setGeometry(QtCore.QRect(10, 382, 211, 31))
        self.label_4.setAutoFillBackground(True)
        self.label_4.setObjectName("label_4")
        
        self.label_5 = QtGui.QLabel(Dialog)
        self.label_5.setGeometry(QtCore.QRect(228, 385, 81, 31))
        self.label_5.setText("")
        self.label_5.setPixmap(QtGui.QPixmap("yubico-logo81.png"))
        self.label_5.setObjectName("label_5")


        # adding buttons
        self.pushButton = QtGui.QPushButton(Dialog)
        self.pushButton.setGeometry(QtCore.QRect(10, 465, 141, 51))
        self.pushButton.setObjectName("pushButton")
        self.pushButton.clicked.connect(self.addCredential)

        self.pushButton_2 = QtGui.QPushButton(Dialog)
        self.pushButton_2.setGeometry(QtCore.QRect(160, 465, 141, 51))
        self.pushButton_2.setObjectName("pushButton_2")
        self.pushButton_2.clicked.connect(self.delCredential)


        # adding separator
        self.line = QtGui.QFrame(Dialog)
        self.line.setGeometry(QtCore.QRect(10, 445, 291, 20))
        self.line.setFrameShape(QtGui.QFrame.HLine)
        self.line.setFrameShadow(QtGui.QFrame.Sunken)
        self.line.setObjectName("line")



        #adding a menu 
        self.menubar = QtGui.QMenuBar(Dialog)
        self.icon = QtGui.QIcon(YUBICO_ICON)
        
        self.menubar.setGeometry(QtCore.QRect(0, 0, 330, 21))
        self.menubar.setObjectName("menubar")
        self.menuFile = QtGui.QMenu(self.menubar)
        self.menuFile.setObjectName("menuFile")
        #self.menuFile.setIcon(self.icon)
        self.menuFile.setTitle("File")

        self.menuItem_1 = QtGui.QAction(Dialog)
        self.menuItem_1.setObjectName("menuItem_1")
        self.menuItem_2 = QtGui.QAction(Dialog)
        self.menuItem_2.setObjectName("menuItem_2")
        self.menuExit = QtGui.QAction(Dialog)
        self.menuExit.setObjectName("menuExit")

        self.menuFile.addAction(self.menuItem_1)
        self.menuFile.addAction(self.menuItem_2)
        self.menuFile.addSeparator()
        self.menuFile.addAction(self.menuExit)

        #exit item of file menu
        self.menuExit.setShortcut('Ctrl+Q')
        self.menuExit.setStatusTip('Exit Yubico Authenticator')
        self.menuExit.triggered.connect(self.menu_exit)
        #change password file menu
        self.menuItem_1.triggered.connect(self.menu_change_password)
        #display about
        self.menuItem_2.triggered.connect(self.menu_about)

        self.menubar.addAction(self.menuFile.menuAction())

        #retranslate & connect
        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)



    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(QtGui.QApplication.translate("Dialog", "Yubico Authenticator", None, QtGui.QApplication.UnicodeUTF8))
        self.progressBar.setFormat(QtGui.QApplication.translate("Dialog", "%vs", None, QtGui.QApplication.UnicodeUTF8))
        self.label.setText(QtGui.QApplication.translate("Dialog", "Time Out", None, QtGui.QApplication.UnicodeUTF8))
        self.pushButton.setText(QtGui.QApplication.translate("Dialog", "Add Account", None, QtGui.QApplication.UnicodeUTF8))
        self.pushButton_2.setText(QtGui.QApplication.translate("Dialog", "Delete Account", None, QtGui.QApplication.UnicodeUTF8))
        self.label_2.setText(QtGui.QApplication.translate("Dialog", "<html><head/><body><p align=\"center\"><span style=\" font-size:11pt; font-weight:600; color:#8cc041;\">ACCOUNT</span></p></body></html>", None, QtGui.QApplication.UnicodeUTF8))
        self.label_3.setText(QtGui.QApplication.translate("Dialog", "<html><head/><body><p align=\"center\"><span style=\" font-size:11pt; font-weight:600; color:#8cc041;\">CODE</span></p></body></html>", None, QtGui.QApplication.UnicodeUTF8))
        self.label_4.setText(QtGui.QApplication.translate("Dialog", "<span style=\" font-size:8pt; color:#C04141;\">Click to copy; double click copy and minimize</span>", None, QtGui.QApplication.UnicodeUTF8))
        
        #retranslate menu
        self.menuFile.setTitle(QtGui.QApplication.translate("Dialog", "File", None, QtGui.QApplication.UnicodeUTF8))
        self.menuItem_1.setText(QtGui.QApplication.translate("Dialog", "Change Password", None, QtGui.QApplication.UnicodeUTF8))
        self.menuItem_2.setText(QtGui.QApplication.translate("Dialog", "About", None, QtGui.QApplication.UnicodeUTF8))
        self.menuExit.setText(QtGui.QApplication.translate("Dialog", "Exit", None, QtGui.QApplication.UnicodeUTF8))

        self.update_progressbar()
        self.refresh()


    def update_progressbar(self):
        
        #compute totp remaining time
        totp_window = (30 - int((time.time() % 30)))

        if totp_window < 6:
             self.progressBar.setStyleSheet(EXPIRE_STYLE)
             self.progressBar.setValue(totp_window)
        else:
            self.progressBar.setStyleSheet(DEFAULT_STYLE)
            self.progressBar.setValue(totp_window)
            if totp_window == 30:
                self.refresh()



    def refresh(self):
        
        # compute codes and check if the NEO is inserted into the USB        
        cred_list = yc.execute_command("calculate_all")
        
        # if None there is no NEO
        if cred_list is None:
            # close the main window
            self.hide_interface()

        else:
            
            #clear the list at the end of the 30 seconds
            self.leftList.clear()
            self.rightList.clear()
            
            for credential in cred_list:
                if credential.algorithm == 'totp':
                    self.leftList.addItem(str(credential.name).decode('utf-8').strip())
                    self.rightList.addItem(str(credential.code))

                else:
                    self.leftList.addItem(str(credential.name).decode('utf-8').strip())
                    
                    self.rightList.addItem('HOTP')
                    #identify the row and set the tooltip
                    value = self.rightList.count()
                    item = self.rightList.item(value-1)
                    item.setToolTip("Click to generate HOTP")
                    #icon = QtGui.QIcon(YUBICO_ICON)
                    #item.setIcon(icon)
            

    def addCredential(self):

        #set data structure for the add command
        new_account = {
        'KEY_TYPE':None,
        'ACCOUNT_NAME':None,
        'SECRET_KEY':None
        }

        #ask the user for new account information
        inputbox = ui_addaccount.Ui_AddAccount(new_account)
        inputbox.show()
        if inputbox.exec_() == 1:
            #strip off white spaces
            new_account['ACCOUNT_NAME'].replace(" ", "")
            new_account['SECRET_KEY'].replace(" ", "")
            #new_account['ACCOUNT_NAME'] = str(new_account['ACCOUNT_NAME']).encode("utf-8").strip()
            #run the PUT command
            yc.execute_command("put", new_account)
            self.refresh()


    #deletes one credential when the button is pressed!
    def delCredential(self):

        #get selected item from the user
        item = self.leftList.currentItem()
        if not item:
            QtGui.QMessageBox.information(QtGui.QWidget(), "Information", "Select 1 credential name on the left panel to delete it")
            return

        #ask for confirmation before delete
        delete, ok = QtGui.QInputDialog.getText(None, "Warning!", "Type \"delete\" to confirm deletion", QtGui.QLineEdit.Normal)
        if delete == "delete":
            if yc.execute_command("delete", item.text()):
                self.refresh()
            else:
                print "Warning: Delete unsuccessfull"

    # check must be a BOOLEAN
    def hide_interface(self):
        if not gm.nosystray:
            self.progress_timer.stop()

            pointer = QtCore.QCoreApplication.instance()
            pointer.setQuitOnLastWindowClosed(False)
            pointer.closeAllWindows()
        else:
            print "nothing for now"


    def closeEvent(self):
        if not gm.nosystray:
            #hide the interface and stop timers
            self.hide_interface()
        else:
            event.ignore()
            self.hide_interface()


    def itemClicked(self, item):
        # 1 click copy the item value as text
        # Handle HOTP load and copy
        if str(item.text()) == "HOTP":
            #get current row
            row = self.rightList.currentRow()
            #get name from the right list widget
            item = self.leftList.item(row)
            hotp_name = item.text()
            hotp = str(yc.execute_command("calculate", hotp_name))
            if hotp is None:
                hotp = "Error"

            #update the item with the generated code
            item = self.rightList.item(row)
            item.setText(hotp)
        
        app = QtCore.QCoreApplication.instance()
        clipboard = app.clipboard()
        clipboard.clear(QtGui.QClipboard.Clipboard)
        clipboard.setText(str(item.text()), QtGui.QClipboard.Clipboard)
            
 
    def itemDoubleClicked(self, item):
        # 2 clicks copy the item value as text and minimize the interface
        # Handle HOTP load copy and hide
        if str(item.text()) == "HOTP":
            #get current row
            row = self.rightList.currentRow()
            #get name from the right list widget
            item = self.leftList.item(row)
            hotp_name = item.text()
            hotp = str(yc.execute_command("calculate", hotp_name))
            if hotp is None:
                hotp = "Error"

            #update the item with the generated code
            item = self.rightList.item(row)
            item.setText(hotp)

        app = QtCore.QCoreApplication.instance()
        clipboard = app.clipboard()
        clipboard.clear(QtGui.QClipboard.Clipboard)
        clipboard.setText(str(item.text()), QtGui.QClipboard.Clipboard)
        self.hide_interface()


    #                       #
    # FILEMENU ITEM ACTIONS #
    #                       #

    def menu_exit(self):
        istance = QtCore.QCoreApplication.instance()
        istance.exit()

    def menu_change_password(self):
        #ask the user for new password
        new_password = []

        inputbox = ui_password_change.Ui_Password_Change(new_password)
        inputbox.show()
        if inputbox.exec_() == 1:
            #run the PUT command
            if len(new_password[0]) != 0:
                #set the new user's provided password
                yc.execute_command("set_code", new_password[0])
                self.refresh()
            else:
                #user picked a blank password, so we unset the code and leave the neo unprotected
                yc.execute_command("unset_code", new_password[0])
                self.refresh()


    def menu_about(self):
        QtGui.QMessageBox.information(QtGui.QWidget(), "Yubico Authenticator", text.copyright)


        # display message
        # title = "Yubico Authenticator - About"
        # message = """ 
        # Copyright (c) 2013-2014 Yubico AB

        # This program is free software: you can redistribute it and/or modify
        # it under the terms of the GNU General Public License as published by
        # the Free Software Foundation, either version 3 of the License, or
        # (at your option) any later version.

        # This program is distributed in the hope that it will be useful, but
        # WITHOUT ANY WARRANTY; without even the implied warranty of
        # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
        # General Public License for more details.

        # You should have received a copy of the GNU General Public License
        # along with this program.  If not, see <http://www.gnu.org/licenses/>."""

        # QtGui.QMessageBox.information(QtGui.QWidget(), title, message)
