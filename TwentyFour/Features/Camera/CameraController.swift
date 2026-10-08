import AVFoundation
import Observation

@Observable
final class CameraController {
  let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private var captureDelegate: PhotoCaptureDelegate?
  var isAuthorized = false

  func start() async {
    isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
    guard isAuthorized else {return}
    if session.inputs.isEmpty {configure()}
    let session = self.session
    Task.detached {session.startRunning()}
  }
  func stop() {
    let session = self.session
    Task.detached { session.stopRunning()}
  }

  func capturePhoto() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      let delegate = PhotoCaptureDelegate(continuation: continuation)
      captureDelegate = delegate
      photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
    }
  }

  private func configure() {
    session.beginConfiguration()
    session.sessionPreset = .photo
    guard
      let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(input),
      session.canAddOutput(photoOutput)
    else {
      session.commitConfiguration()
      return
    }
    session.addInput(input)
    session.addOutput(photoOutput)
    session.commitConfiguration()
  }
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let continuation: CheckedContinuation<Data, Error>

  init(continuation: CheckedContinuation<Data, Error>) {
    self.continuation = continuation
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error {
      continuation.resume(throwing: error)
      return
    }
    guard let data = photo.fileDataRepresentation() else {
      continuation.resume(throwing: CameraError.noPhotoData)
      return
    }
    continuation.resume(returning: data)
  }
}

enum CameraError: Error {
  case noPhotoData
}