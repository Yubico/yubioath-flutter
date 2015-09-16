from PySide.QtGui import QCheckBox, QDialog, QGridLayout, QLabel, \
    QDialogButtonBox

ENABLE_CCID_URL = 'http://yubi.co/modeswitch'
LABEL_TEXT = '''<b>CCID (smart card capabilities) is disabled on the inserted YubiKey.</b><br><br>
                Without CCID enabled, you will only be able to store 2 credentials.<br><br>
                <a href="%s">Learn how to enable CCID</a><br>'''


class CcidDisabledDialog(QDialog):

    def __init__(self, parent=None):
        super(CcidDisabledDialog, self).__init__()

        self.setWindowTitle("CCID disabled")
        self.do_not_ask_again = QCheckBox('Do not ask this again')
        label = QLabel(LABEL_TEXT % ENABLE_CCID_URL, openExternalLinks=True)
        layout = QGridLayout()
        layout.addWidget(label, 1, 1)
        layout.addWidget(self.do_not_ask_again, 2, 1)

        buttonBox = QDialogButtonBox(QDialogButtonBox.Ok)
        buttonBox.accepted.connect(self.close)

        layout.addWidget(buttonBox, 3, 1)
        self.setLayout(layout)
