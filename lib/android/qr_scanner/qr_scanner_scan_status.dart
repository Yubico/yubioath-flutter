/// Status of the scanning process
/// scanning - showing preview and scanning it for finding credential QR code
/// error - a QR code has been found but is not a credential
/// success - a QR code has been found and is a usable credential
enum ScanStatus { scanning, error, success }
