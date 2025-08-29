//
//  QRScannerView.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        QRScannerViewController(onCodeScanned: onCodeScanned)
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

struct QRScannerScreen: View {
    @ObservedObject var networkManager: MobileNetworkManager
    @State private var scannedCode: String? = nil
    @Binding var showingQRCodeScreen: Bool

    var body: some View {
        VStack {
            PlaceholderItem(
                systemImage: "qrcode",
                systemImageColor: Color.accent,
                title: "Scan QR Code",
                subtitle: "Scan QR code from SerialPlotter.",
                isProminent: true
            )
            .frame(height: 250)
            
            QRScannerView { code in
                scannedCode = code
                networkManager.handleQRCode(code)
                showingQRCodeScreen = false
            }
            .overlay(
                LinearGradient(
                    colors: [.indigo, .accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.color)
            )
            .overlay(
                Group {
                    if #available(iOS 18.0, visionOS 2.0, *) {
                        Image(systemName: "viewfinder")
                            .resizable()
                            .fontWeight(.ultraLight)
                            .scaledToFit()
                            .symbolEffect(.breathe)
                            .frame(width: 225, height: 225)
                    } else {
                        Image(systemName: "viewfinder")
                            .resizable()
                            .fontWeight(.ultraLight)
                            .scaledToFit()
                            .frame(width: 225, height: 225)
                    }
                }
            )
            .mask(RoundedRectangle(cornerRadius: 48))
            .mask(RoundedRectangle(cornerRadius: 48).padding().blur(radius: 8))
            .scaleEffect(0.95)
        }
    }
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let onCodeScanned: (String) -> Void
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    init(onCodeScanned: @escaping (String) -> Void) {
        self.onCodeScanned = onCodeScanned
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            onCodeScanned(stringValue)
        }
    }
}
