import UIKit
import AVFoundation
import AudioToolbox

@MainActor
protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(code: String)
}

@MainActor
class ScannerViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: ScannerViewControllerDelegate?
    
    private let sessionQueue = DispatchQueue(label: "com.ecoscan.camera.session")
    
    private let focusView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = .clear
        return view
    }()
    
    private actor ScanningState {
        private(set) var isScanning = true
        
        func setScanning(_ value: Bool) {
            isScanning = value
        }
    }
    
    private let scanningState = ScanningState()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFocusView()
        
        Task {
            await checkCameraPermission()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupFocusView() {
        view.addSubview(focusView)
        focusView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        focusView.center = view.center
    }
    
    private func startCapture() {
        guard let session = captureSession else { return }
        sessionQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    private func stopCapture() {
        guard let session = captureSession else { return }
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }
    
    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await setupCameraSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await setupCameraSession()
            } else {
                await MainActor.run {
                    handleCameraPermissionDenied()
                }
            }
        case .denied, .restricted:
            await MainActor.run {
                handleCameraPermissionDenied()
            }
        @unknown default:
            break
        }
    }
    
    private func handleCameraPermissionDenied() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access in Settings to scan barcodes.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func setupCameraSession() async {
        return await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let session = AVCaptureSession()
                
                guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                    print("Camera error: No video device found")
                    continuation.resume()
                    return
                }
                
                do {
                    let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                    
                    guard session.canAddInput(videoInput) else {
                        print("Camera error: Couldn't add video input")
                        continuation.resume()
                        return
                    }
                    session.addInput(videoInput)
                    
                    let metadataOutput = AVCaptureMetadataOutput()
                    
                    guard session.canAddOutput(metadataOutput) else {
                        print("Camera error: Couldn't add metadata output")
                        continuation.resume()
                        return
                    }
                    session.addOutput(metadataOutput)
                    
                    metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
                    metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce]
                    
                    let scanRect = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
                    metadataOutput.rectOfInterest = scanRect
                    
                    Task { @MainActor in
                        self.captureSession = session
                        
                        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                        previewLayer.frame = self.view.layer.bounds
                        previewLayer.videoGravity = .resizeAspectFill
                        self.view.layer.addSublayer(previewLayer)
                        self.previewLayer = previewLayer
                        
                        session.startRunning()
                        continuation.resume()
                    }
                    
                } catch {
                    print("Camera error: \(error.localizedDescription)")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScannerViewController: @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                  didOutput metadataObjects: [AVMetadataObject],
                                  from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let scannedValue = metadataObject.stringValue else {
            return
        }
        
        // Create copies of the values we need before dispatching
        let bounds = metadataObject.bounds
        let barcode = String(scannedValue)
        
        // Immediately dispatch to main queue to handle UI and delegate calls
        DispatchQueue.main.async { [weak self, bounds, barcode] in
            guard let self = self else { return }
            
            Task {
                guard await self.scanningState.isScanning else { return }
                
                // Update UI using the captured bounds
                UIView.animate(withDuration: 0.3) {
                    self.focusView.frame = bounds
                    self.focusView.layer.borderColor = UIColor.green.cgColor
                }
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                await self.scanningState.setScanning(false)
                
                // Use the captured barcode value
                self.delegate?.didFind(code: barcode)
            }
        }
    }
}

// MARK: - Camera Errors
private enum CameraError: Error {
    case inputError
    case outputError
} 
