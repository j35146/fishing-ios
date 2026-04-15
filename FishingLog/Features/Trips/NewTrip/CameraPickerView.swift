import SwiftUI

// 相机拍照/录像结果
enum CameraCaptureResult {
    case photo(UIImage)
    case video(URL)
}

/// UIImagePickerController 包装，支持拍照和录像
struct CameraPickerView: UIViewControllerRepresentable {
    enum CaptureMode { case photo, video }

    let mode: CaptureMode
    let onCapture: (CameraCaptureResult) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        switch mode {
        case .photo:
            picker.cameraCaptureMode = .photo
        case .video:
            picker.mediaTypes = ["public.movie"]
            picker.cameraCaptureMode = .video
            picker.videoQuality = .typeMedium  // 720p 自动压缩
            picker.videoMaximumDuration = 300   // 最长5分钟
        }
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(.photo(image))
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.onCapture(.video(videoURL))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
