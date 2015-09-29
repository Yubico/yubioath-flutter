from PySide.QtGui import QCheckBox, QGridLayout, QLabel, \
    QDialogButtonBox
from yubioath.gui.messages import ccid_disabled
from yubioath.yubicommon.qt import Dialog

ENABLE_CCID_URL = 'http://yubi.co/modeswitch'


class CcidDisabledDialog(Dialog):

    def __init__(self, parent=None):
        super(CcidDisabledDialog, self).__init__()

        self.setWindowTitle("CCID disabled")
        self.do_not_ask_again = QCheckBox('Do not ask this again')
        label = QLabel(ccid_disabled % ENABLE_CCID_URL, openExternalLinks=True)
        layout = QGridLayout(self)
        layout.addWidget(label, 1, 1)
        layout.addWidget(self.do_not_ask_again, 2, 1)

        buttonBox = QDialogButtonBox(QDialogButtonBox.Ok)
        buttonBox.accepted.connect(self.close)

        layout.addWidget(buttonBox, 3, 1)
