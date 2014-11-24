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

import os
import sys
import text
import time
import signal
import argparse
import ui_main as gl
import commands as yc

from PySide import QtCore
from PySide import QtGui



#####################
#Command line input #
#####################
parser = argparse.ArgumentParser(description="Yubico Authenticator", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
# Add more options if you like
parser.add_argument('--version', action='version', version='Yubico Authenticator %s' % text.version)
parser.add_argument('--disable-systray', dest='nosystray', action='store_true', help="if disable the authenticator will not run in systray mode")
parser.set_defaults(nosystray=False)
args = parser.parse_args()

nosystray = args.nosystray



signal.signal(signal.SIGINT, signal.SIG_DFL)

YUBICO_ICON = "yubioath-48.png"

#FIX FOR PYINSTALLER
if getattr(sys, 'frozen', False):
    # we are running in a PyInstaller bundle
    basedir = sys._MEIPASS
else:
    # we are running in a normal Python environment
    basedir = os.path.dirname(__file__)

# Font fix for OSX Mavericks
if sys.platform == 'darwin':
    from platform import mac_ver
    if tuple(mac_ver()[0].split('.')) >= (10, 9):
        QtGui.QFont.insertSubstitution(".Lucida Grande UI", "Lucida Grande")


QtCore.QCoreApplication.setOrganizationName('Yubico')
QtCore.QCoreApplication.setOrganizationDomain('yubico.com')
QtCore.QCoreApplication.setApplicationName('YubiKey Authenticator')



class SystemTrayIcon(QtGui.QSystemTrayIcon):
	def __init__(self, parent=None):
		QtGui.QSystemTrayIcon.__init__(self, parent)
		

		#FIX FOR PYINSTALLER
		if getattr(sys, 'frozen', False):
		    # we are running in a PyInstaller bundle
		    basedir = sys._MEIPASS
		else:
		    # we are running in a normal Python environment
		    basedir = os.path.dirname(__file__)


		#set working dir for the icon else it wont show up when executed from the nsis .lnk
		self.setIcon(QtGui.QIcon(os.path.join(basedir, YUBICO_ICON)))
		self.iconMenu = QtGui.QMenu(parent)
		self.setToolTip('Yubico Authenticator')

		

		appcalc = self.iconMenu.addAction("Show Code")
		appinstr = self.iconMenu.addAction("Instructions")
		appabout = self.iconMenu.addAction("About")
		appexit = self.iconMenu.addAction("Exit")
		self.setContextMenu(self.iconMenu)

		self.connect(appcalc, QtCore.SIGNAL('triggered()') ,self.appCalc)
		self.connect(appinstr, QtCore.SIGNAL('triggered()') ,self.appInstructions)
		self.connect(appabout, QtCore.SIGNAL('triggered()') ,self.appShowAbout)
		self.connect(appexit, QtCore.SIGNAL('triggered()'), self.appExit)


		self.show()
		#try to pop the application
		if sys.platform == "darwin":
			self.appCalc()


	def appCalc(self):
		#instantiate the new windows but don't show it yet (needed for qmessagebox parent)
		self.myapp = Window()
		#return presence and if the neo is password protected	
		neo, is_protected = yc.check_neo_presence()
		#check if the neo is present
		if neo:
			#check if it is password protected
			if is_protected:
				#hide icon to avoid double clicks and glitches.
				self.hide()
				password, ok = QtGui.QInputDialog.getText(self.myapp, "Password", "Password:", QtGui.QLineEdit.Password)
				password = password.encode('utf-8').strip()
				self.show()
				if ok:
					#do soemthing
					if yc.unlock_applet(neo, password):
						#success! now run the authenticator
						#time.sleep(0.5)	
						self.myapp = Window()
						self.myapp.show()
						self.myapp.activateWindow()
						#self.myapp.raise_()		
					else:
						#fail for some reasons
						QtGui.QMessageBox.information(self.myapp, self.tr("Warning: No Yubikey NEO detected"),
                                               text.no_yubikey_no_m82, QtGui.QMessageBox.Ok)			
						return
				else:
					QtGui.QMessageBox.information(QtGui.QWidget(), self.tr("Warning!"), self.tr("A password is required to access the Yubico Authenticator."))			
					return
			#the neo is not protected go on with standard operations!
			else:
				#time.sleep(0.5)	
				self.myapp = Window()
				self.myapp.setWindowTitle("Authenticator Authenticator")
				self.myapp.setWindowIcon(QtGui.QIcon(os.path.join(basedir, YUBICO_ICON)))
				self.myapp.show()
				self.myapp.activateWindow()
				#self.myapp.raise_()
		else:
			#there is no neo
			QtGui.QMessageBox.information(self.myapp, self.tr("Warning: No Yubikey NEO detected"),
                                               text.no_yubikey_no_m82, QtGui.QMessageBox.Ok)
			

	def appShowAbout(self):
		QtGui.QMessageBox.information(QtGui.QWidget(), self.tr("Yubico Authenticator"), self.tr(text.copyright))


	def appInstructions(self):
		QtGui.QMessageBox.information(QtGui.QWidget(), self.tr("Yubico Authenticator"), self.tr(text.instructions))

	def appExit(self):
		sys.exit(0)


	def iconActivated(self, reason):
		if reason == QtGui.QSystemTrayIcon.DoubleClick:
			self.appCalc()




# main window class
class Window(QtGui.QWidget):
    def __init__(self, parent=None):
        super(Window, self).__init__(parent)
        #FIX FOR PYINSTALLER 
        if getattr(sys, 'frozen', False):
        # we are running in a PyInstaller bundle 
       		basedir = sys._MEIPASS 
        else: 
        # we are running in a normal Python environment 
        	basedir = os.path.dirname(__file__) 

        windowIcon = QtGui.QIcon(os.path.join(basedir, YUBICO_ICON))
        self.setWindowIcon(windowIcon)
        self.ui = gl.Ui_Dialog()
        self.ui.setupUi(self)



    def closeEvent(self, event):
    	if not nosystray:
    		#handle the close event (x) top right corner
    		self.ui.closeEvent()
    	else:
			event.ignore()
			#self.ui.progress_timer.stop()

			pointer = QtCore.QCoreApplication.instance()
			pointer.setQuitOnLastWindowClosed(True)
			self.showMinimized()


if __name__ == "__main__":
	
	#check if systray mode is enabled
	if not nosystray:

		app = QtGui.QApplication(sys.argv)
		app.setQuitOnLastWindowClosed(False)
		
		trayIcon = SystemTrayIcon()
		QtCore.QObject.connect(trayIcon, QtCore.SIGNAL("activated(QSystemTrayIcon::ActivationReason)"), trayIcon.iconActivated)
		trayIcon.show()

		sys.exit(app.exec_())

	else:
		#the user selected --disable-systray mode
		app = QtGui.QApplication(sys.argv)
		app.setQuitOnLastWindowClosed(False)
		
		# trayIcon = SystemTrayIcon()
		# QtCore.QObject.connect(trayIcon, QtCore.SIGNAL("activated(QSystemTrayIcon::ActivationReason)"), trayIcon.iconActivated)
		# trayIcon.show()
		neo, is_protected = yc.check_neo_presence()
		#check if the neo is present
		if neo:
			#check if it is password protected
			if is_protected:
				#hide icon to avoid double clicks and glitches.
				password, ok = QtGui.QInputDialog.getText(self, "Password", "Password:", QtGui.QLineEdit.Password)
				if ok:
				#do soemthing
					if yc.unlock_applet(neo, password):
						#success! now run the authenticator
						#time.sleep(0.5)
						main_window = Window()
						main_window.show()
						main_window.activateWindow()
					else:
						#fail for some reasons
						send_message("Warning: No Yubikey NEO detected", text.no_yubikey_no_m82, 0)
						sys.exit(-2)
						#return
				else:
					send_message("Error:", "A password is required to access the Yubico Authenticator.", 1)
					sys.exit(-3)
					#return
			#the neo is not protected go on with standard operations!
			else:
				#time.sleep(0.5)	
				main_window = Window()
				main_window.show()
				main_window.activateWindow()
				#self.myapp.raise_()
		else:
			#there is no neo
			send_message("Warning: No Yubikey NEO detected", text.no_yubikey_no_m82, 0)
			sys.exit(-2)

		sys.exit(app.exec_())
