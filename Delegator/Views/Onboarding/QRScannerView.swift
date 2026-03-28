//
//  QRScannerView.swift
//  Delegator
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showPermissionDenied()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Overlay
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = .clear
        view.addSubview(overlay)

        let scanFrame = CGRect(
            x: view.bounds.midX - 120,
            y: view.bounds.midY - 120,
            width: 240,
            height: 240
        )
        let border = UIView(frame: scanFrame)
        border.layer.borderColor = UIColor(red: 1, green: 0.84, blue: 0.04, alpha: 0.8).cgColor
        border.layer.borderWidth = 2
        border.layer.cornerRadius = 12
        border.backgroundColor = .clear
        overlay.addSubview(border)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func showPermissionDenied() {
        let label = UILabel()
        label.text = "Camera access required\nfor QR scanning"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue,
              value.count <= 2048 else { return }

        hasScanned = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onCodeScanned?(value)
    }
}
