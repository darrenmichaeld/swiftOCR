import SwiftUI
import Photos
import TOCropViewController

struct ContentView: View {
    @State private var isCameraActive = false
    @State private var capturedImage: UIImage?
    @State private var cameraPermissionGranted = false
    @State private var photoLibraryPermissionGranted = false
    @State private var showImageCropper = false

    var body: some View {
        VStack {
            if isCameraActive {
                if cameraPermissionGranted {
                    CameraView { image in
                        self.capturedImage = image
                        self.isCameraActive = false
                        self.showImageCropper = true // Show cropper after capturing image
                    }
                } else {
                    Text("Camera permission not granted.")
                }
            } else {
                Button(action: {
                    requestPermissions { granted in
                        if granted {
                            self.isCameraActive = true
                        } else {
                            print("Permissions not granted.")
                        }
                    }
                }) {
                    Text("Capture Photo")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                if let capturedImage = capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .sheet(isPresented: $showImageCropper) {
            if let image = capturedImage {
                ImageCropperView(image: image) { croppedImage in
                    self.capturedImage = croppedImage
                    UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil) // Save cropped image
                }
            }
        }
    }

    /// Request both camera and photo library permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        requestCameraPermission { cameraGranted in
            self.cameraPermissionGranted = cameraGranted
            if cameraGranted {
                requestPhotoLibraryPermission { libraryGranted in
                    self.photoLibraryPermissionGranted = libraryGranted
                    completion(cameraGranted && libraryGranted)
                }
            } else {
                completion(false)
            }
        }
    }

    /// Request camera permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Request photo library permission
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
}

struct ImageCropperView: UIViewControllerRepresentable {
    var image: UIImage
    var onCrop: (UIImage) -> Void

    func makeUIViewController(context: Context) -> TOCropViewController {
        let cropViewController = TOCropViewController(image: image)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: TOCropViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onCrop: onCrop)
    }

    class Coordinator: NSObject, TOCropViewControllerDelegate {
        var parent: ImageCropperView
        var onCrop: (UIImage) -> Void

        init(_ parent: ImageCropperView, onCrop: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onCrop = onCrop
        }

        // Called when the user successfully crops the image
        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
            cropViewController.dismiss(animated: true) {
                self.onCrop(image) // Pass cropped image back
                
                // Save the cropped image to the Photos Library
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                print("Cropped image saved to Photos Library")
            }
        }

        // Called when the user cancels the cropping
        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            cropViewController.dismiss(animated: true, completion: nil)
        }
    }
}
