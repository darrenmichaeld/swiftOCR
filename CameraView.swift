import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        var onCapture: (UIImage) -> Void
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?

        init(parent: CameraView, onCapture: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onCapture = onCapture
        }

        @objc func capturePhoto() {
            guard let photoOutput = photoOutput else { return }
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation() else {
                print("Error capturing photo: \(error?.localizedDescription ?? "No error")")
                return
            }
            if let capturedImage = UIImage(data: imageData) {
                
                onCapture(capturedImage)
            }
        }
    }

    var onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, onCapture: onCapture)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera!")
            return viewController
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)

            let photoOutput = AVCapturePhotoOutput()
            captureSession.addOutput(photoOutput)

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = viewController.view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            viewController.view.layer.addSublayer(previewLayer)

            captureSession.startRunning()

            let photoButton = UIButton(type: .system)
            photoButton.setTitle("Capture", for: .normal)
            photoButton.addTarget(context.coordinator, action: #selector(context.coordinator.capturePhoto), for: .touchUpInside)
            viewController.view.addSubview(photoButton)

            photoButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                photoButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                photoButton.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
            ])

            // Assign the capture session and photo output to the coordinator
            context.coordinator.captureSession = captureSession
            context.coordinator.photoOutput = photoOutput

            return viewController
        } catch let error {
            print("Error setting up camera: \(error.localizedDescription)")
            return viewController
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
