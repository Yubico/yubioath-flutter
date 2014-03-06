# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '.\ui_password_change.ui'
#
# Created: Thu Feb 20 16:27:14 2014
#      by: pyside-uic 0.2.15 running on PySide 1.2.1
#
# WARNING! All changes made in this file will be lost!

from PySide import QtCore, QtGui

class Ui_Password_Change(QtGui.QDialog):
    def __init__(self, new_password, parent=None):
        super(Ui_Password_Change, self).__init__(parent)

        self.new_password = new_password

        #Dialog.setObjectName("Dialog")
        self.resize(344, 199)
        self.buttonBox = QtGui.QDialogButtonBox(self)
        self.buttonBox.setGeometry(QtCore.QRect(160, 160, 171, 32))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Ok)
        self.buttonBox.setObjectName("buttonBox")
        self.lineEdit_2 = QtGui.QLineEdit(self)
        self.lineEdit_2.setGeometry(QtCore.QRect(10, 30, 321, 41))
        font = QtGui.QFont()
        font.setPointSize(12)
        self.lineEdit_2.setFont(font)
        self.lineEdit_2.setText("")
        self.lineEdit_2.setObjectName("lineEdit_2")
        self.lineEdit_3 = QtGui.QLineEdit(self)
        self.lineEdit_3.setGeometry(QtCore.QRect(10, 110, 321, 41))
        font = QtGui.QFont()
        font.setPointSize(12)
        self.lineEdit_3.setFont(font)
        self.lineEdit_3.setObjectName("lineEdit_3")
        self.label_2 = QtGui.QLabel(self)
        self.label_2.setGeometry(QtCore.QRect(10, 0, 111, 31))
        font = QtGui.QFont()
        font.setPointSize(12)
        self.label_2.setFont(font)
        self.label_2.setObjectName("label_2")
        self.label_3 = QtGui.QLabel(self)
        self.label_3.setGeometry(QtCore.QRect(10, 80, 173, 19))
        self.label_3.setMinimumSize(QtCore.QSize(173, 0))
        font = QtGui.QFont()
        font.setPointSize(12)
        self.label_3.setFont(font)
        self.label_3.setObjectName("label_3")


        self.buttonBox.accepted.connect(self.verify)
        #QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("accepted()"), self.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("rejected()"), self.reject)
        QtCore.QMetaObject.connectSlotsByName(self)

        # Define window text
        self.setWindowTitle("Set Password")
        self.label_2.setText("New password")
        self.label_3.setText("Confirm new password")

        #set place holder text
        self.lineEdit_2.setPlaceholderText("New password")
        self.lineEdit_3.setPlaceholderText("Confirm new password")

        #defin.e echo mode
        self.lineEdit_2.setEchoMode(QtGui.QLineEdit.Password)
        self.lineEdit_3.setEchoMode(QtGui.QLineEdit.Password)

        self.setModal(True)
        


    def verify(self):
        #set the data and quit
        # WARNING THE lineEdit.text() RETURNS A UNICODE 
        self.new_password.append(self.lineEdit_2.text())
        self.new_password.append(self.lineEdit_3.text()) 

        if self.new_password[0] != self.new_password[1]:

            QtGui.QMessageBox.information(QtGui.QWidget(), self.tr("Warning!"), self.tr("Passwords do not match. Please try again"))
            self.reject()


        self.accept()


