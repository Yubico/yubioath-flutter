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

import base64
from PySide import QtCore, QtGui



class Ui_AddAccount(QtGui.QDialog):
    def __init__(self, new_account, parent=None):
        super(Ui_AddAccount, self).__init__(parent)

        self.new_account = new_account

        self.resize(285, 208)
        self.label = QtGui.QLabel(self)
        self.label.setGeometry(QtCore.QRect(10, 10, 271, 21))
        font = QtGui.QFont()
        font.setPointSize(11)
        font.setWeight(50)
        font.setBold(False)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.label_2 = QtGui.QLabel(self)
        self.label_2.setGeometry(QtCore.QRect(10, 60, 61, 20))
        font = QtGui.QFont()
        font.setPointSize(11)
        font.setWeight(50)
        font.setBold(False)
        self.label_2.setFont(font)
        self.label_2.setObjectName("label_2")
        self.label_3 = QtGui.QLabel(self)
        self.label_3.setGeometry(QtCore.QRect(10, 110, 81, 16))
        font = QtGui.QFont()
        font.setPointSize(11)
        font.setWeight(50)
        font.setBold(False)
        self.label_3.setFont(font)
        self.label_3.setTextFormat(QtCore.Qt.PlainText)
        self.label_3.setObjectName("label_3")

        self.lineEdit = QtGui.QLineEdit(self)
        self.lineEdit.setGeometry(QtCore.QRect(10, 80, 261, 20))
        self.lineEdit.setObjectName("lineEdit")
        
        self.buttonBox = QtGui.QDialogButtonBox(self)
        self.buttonBox.setGeometry(QtCore.QRect(120, 170, 156, 23))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Ok)
        self.buttonBox.setObjectName("buttonBox")
        self.buttonBox.accepted.connect(self.verify)
        #QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("accepted()"), self.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("rejected()"), self.reject)
        
        self.comboBox = QtGui.QComboBox(self)
        self.comboBox.setGeometry(QtCore.QRect(10, 30, 261, 21))
        self.comboBox.setObjectName("comboBox")
        self.comboBox.addItem("time-based")
        self.comboBox.addItem("counter-based")
        
        self.lineEdit_2 = QtGui.QLineEdit(self)
        self.lineEdit_2.setGeometry(QtCore.QRect(10, 130, 261, 20))
        self.lineEdit_2.setObjectName("lineEdit_2")


        # Define window text
        self.setWindowTitle("Add New Account")
        self.label.setText("Key Type")
        self.label_2.setText("Account")
        self.label_3.setText("Secret Key")

        #set place holder text
        self.lineEdit.setPlaceholderText("tom@example.com")
        self.lineEdit_2.setPlaceholderText("thei ncre dibl ehul kisi nmod hex!")
        # set modal option
        self.setModal(True)
        


    def verify(self):
        #set the data and quit
        # WARNING THE lineEdit.text() RETURNS A UNICODE 
        self.new_account['ACCOUNT_NAME'] = self.lineEdit.text().encode('utf-8')
        #remove whitespace
        self.new_account['SECRET_KEY'] = self.lineEdit_2.text().replace(" ", "")

        #FIX DROPBOX 26 character key
        #padding N characters of = if string mod 8 is not 0 - in Python mod takes the sign of the denominator
        self.new_account['SECRET_KEY'] += '=' * (-len(self.new_account['SECRET_KEY']) % 8)        

        try:
            self.new_account['SECRET_KEY'] = base64.b32decode(self.new_account['SECRET_KEY'], True)
            
        except Exception:
            QtGui.QMessageBox.about(self, 'Error','Input can only be a valid TOTP base32 encoded key.')
            self.reject()
            return

        #select if TOTP or HOTP key type
        self.new_account['KEY_TYPE'] = self.comboBox.currentText()
        #accept the dialog
        self.accept()
