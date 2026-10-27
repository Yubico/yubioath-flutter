/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import AVFoundation
import Flutter
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import Vision

final class QrScanner {
    private let channel: FlutterMethodChannel
    private var scanning = false

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.yubico.authenticator/qr", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scanImage":
            guard let bytes = call.arguments as? FlutterStandardTypedData else {
                return result(FlutterError(code: "invalid_image", message: "Expected image bytes", details: nil))
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let value = try Self.decode(bytes.data)
                    DispatchQueue.main.async { result(value) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "invalid_image", message: error.localizedDescription, details: nil))
                    }
                }
            }
        case "scan":
            guard !scanning else {
                return result(FlutterError(code: "busy", message: "A QR scan is already in progress", details: nil))
            }
            guard let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })?
                .windows.first(where: \.isKeyWindow)?.rootViewController else {
                return result(FlutterError(code: "unavailable", message: "No active scanner window", details: nil))
            }
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            scanning = true
            let scanner = QrScannerController(strings: call.arguments as? [String: String] ?? [:])
            let navigation = UINavigationController(rootViewController: scanner)
            navigation.modalPresentationStyle = .fullScreen
            scanner.complete = { [weak self, weak navigation] value, error in
                navigation?.dismiss(animated: true) {
                    self?.scanning = false
                    if let error { result(error) } else { result(value) }
                }
            }
            presenter.present(navigation, animated: true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    static func decode(_ data: Data) throws -> String? {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        #if targetEnvironment(simulator)
        // Simulator runtimes may not provide Vision's default inference device.
        request.usesCPUOnly = true
        #endif
        try VNImageRequestHandler(data: data).perform([request])
        return request.results?.compactMap(\.payloadStringValue).first
    }
}

private final class QrScannerController: UIViewController,
    AVCaptureMetadataOutputObjectsDelegate, PHPickerViewControllerDelegate {
    var complete: ((String?, FlutterError?) -> Void)?
    private let strings: [String: String]
    private let session = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "com.yubico.authenticator.qr.camera")
    private var preview: AVCaptureVideoPreviewLayer?
    private let message = UILabel()
    private var configured = false
    private var finished = false
    private var pickingImage = false
    private var observers: [NSObjectProtocol] = []

    init(strings: [String: String]) {
        self.strings = strings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = strings["title"]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: strings["cancel"], style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: strings["image"], style: .plain, target: self, action: #selector(selectImage))
        message.text = strings["instructions"]
        message.textColor = .white
        message.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        message.numberOfLines = 0
        message.textAlignment = .center
        message.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(message)
        NSLayoutConstraint.activate([
            message.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            message.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            message.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.stopCamera() })
        observers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.startCamera() })
        observers.append(center.addObserver(
            forName: .AVCaptureSessionRuntimeError, object: session, queue: .main
        ) { [weak self] notification in
            guard let self, !self.finished else { return }
            let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError
            self.finish(error: FlutterError(code: "camera_error", message: error?.localizedDescription ?? "Camera failed", details: nil))
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
        if #available(iOS 17.0, *), let connection = preview?.connection {
            let angle: CGFloat
            switch view.window?.windowScene?.interfaceOrientation {
            case .landscapeLeft: angle = 0
            case .landscapeRight: angle = 180
            case .portraitUpsideDown: angle = 270
            default: angle = 90
            }
            if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
        } else if let connection = preview?.connection, connection.isVideoOrientationSupported {
            switch view.window?.windowScene?.interfaceOrientation {
            case .landscapeLeft: connection.videoOrientation = .landscapeLeft
            case .landscapeRight: connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
            default: connection.videoOrientation = .portrait
            }
        }
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    private func startCamera() {
        guard !finished, !pickingImage, view.window != nil,
              UIApplication.shared.applicationState == .active else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async { self?.startCamera() }
            }
        case .authorized:
            configureCamera()
        default:
            message.text = strings["permission"]
            let settings = UIBarButtonItem(title: strings["settings"], style: .plain, target: self, action: #selector(openSettings))
            toolbarItems = [UIBarButtonItem(systemItem: .flexibleSpace), settings, UIBarButtonItem(systemItem: .flexibleSpace)]
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }

    private func configureCamera() {
        navigationController?.setToolbarHidden(true, animated: true)
        message.text = strings["instructions"]
        if !configured {
            do {
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    throw NSError(domain: "QrScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "No rear camera is available. Select an image instead."])
                }
                let input = try AVCaptureDeviceInput(device: camera)
                let output = AVCaptureMetadataOutput()
                session.beginConfiguration()
                defer { session.commitConfiguration() }
                guard session.canAddInput(input) else {
                    throw NSError(domain: "QrScanner", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot open the camera"])
                }
                session.addInput(input)
                guard session.canAddOutput(output) else {
                    session.removeInput(input)
                    throw NSError(domain: "QrScanner", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot configure QR scanning"])
                }
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.qr]
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspectFill
                view.layer.insertSublayer(layer, at: 0)
                preview = layer
                configured = true
                view.setNeedsLayout()
            } catch {
                message.text = error.localizedDescription
                return
            }
        }
        cameraQueue.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    private func stopCamera() {
        cameraQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !pickingImage,
              let value = metadataObjects.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).first else { return }
        finish(value: value)
    }

    private func finish(value: String? = nil, error: FlutterError? = nil) {
        guard !finished else { return }
        finished = true
        stopCamera()
        complete?(value, error)
        complete = nil
    }

    @objc private func cancel() { finish() }

    @objc private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    @objc private func selectImage() {
        guard !pickingImage, !finished else { return }
        pickingImage = true
        stopCamera()
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            guard let provider = results.first?.itemProvider else {
                self.pickingImage = false
                self.startCamera()
                return
            }
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                do {
                    if let error { throw error }
                    guard let data else { throw NSError(domain: "QrScanner", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not read the selected image"]) }
                    let value = try QrScanner.decode(data)
                    DispatchQueue.main.async {
                        guard let self, !self.finished else { return }
                        self.pickingImage = false
                        if let value { self.finish(value: value) }
                        else {
                            self.startCamera()
                            self.message.text = self.strings["notFound"]
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.finish(error: FlutterError(code: "invalid_image", message: error.localizedDescription, details: nil))
                    }
                }
            }
        }
    }
}
