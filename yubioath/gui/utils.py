def is_minimized(window):
    """Returns True iff the window is minimized or has been sent to the tray"""
    return not window.isVisible() or window.isMinimized()