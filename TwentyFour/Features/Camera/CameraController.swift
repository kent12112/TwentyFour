import AVFoundation
import Observation

@Observable
final class CameraController {
  let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private var captureDelegate: PhotoCaptureDelegate?
  private var currentInput: AVCaptureDeviceInput?
  // reads how the phone is physically held, even though the screen is locked to portrait
  private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
  var isAuthorized = false
  var isFlashOn = true
  var position: AVCaptureDevice.Position = .back
  var isExposureLocked = false

  func start() async {
    isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
    guard isAuthorized else { return }
    if session.inputs.isEmpty { configure() }
    let session = self.session
    Task.detached { session.startRunning() }
  }
  func stop() {
    let session = self.session
    Task.detached { session.stopRunning() }
  }

  func capturePhoto() async throws -> Data {
    let settings = AVCapturePhotoSettings()
    if isFlashOn && photoOutput.supportedFlashModes.contains(.on) {
      settings.flashMode = .on
    } else {
      settings.flashMode = .off
    }
    // turn the photo to match how the phone is held: sideways shots become landscape photos
    if let rotationCoordinator, let connection = photoOutput.connection(with: .video) {
      let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
      if connection.isVideoRotationAngleSupported(angle) {
        connection.videoRotationAngle = angle
      }
    }
    return try await withCheckedThrowingContinuation { continuation in
      let delegate = PhotoCaptureDelegate(continuation: continuation)
      captureDelegate = delegate
      photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
  }

  // switch between the back and front camera
  func flip() {
    let newPosition: AVCaptureDevice.Position = position == .back ? .front : .back
    guard
      let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
      let newInput = try? AVCaptureDeviceInput(device: camera)
    else { return }

    session.beginConfiguration()
    if let currentInput { session.removeInput(currentInput) }
    if session.canAddInput(newInput) {
      session.addInput(newInput)
      currentInput = newInput
      position = newPosition
      rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
    } else if let currentInput {
      session.addInput(currentInput)  // put the old camera back if the new one fails
    }
    session.commitConfiguration()
    isExposureLocked = false
  }

  // AE lock: freeze the current brightness, or go back to automatic
  func toggleExposureLock() {
    guard let device = currentInput?.device else { return }
    do {
      try device.lockForConfiguration()
      if isExposureLocked {
        device.exposureMode = .continuousAutoExposure
        isExposureLocked = false
      } else if device.isExposureModeSupported(.locked) {
        device.exposureMode = .locked
        isExposureLocked = true
      }
      device.unlockForConfiguration()
    } catch {
      print("Exposure lock failed:", error)
    }
  }

  private func configure() {
    session.beginConfiguration()
    session.sessionPreset = .photo
    guard
      let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
      let input = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(input),
      session.canAddOutput(photoOutput)
    else {
      session.commitConfiguration()
      return
    }
    session.addInput(input)
    session.addOutput(photoOutput)
    currentInput = input
    rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
    session.commitConfiguration()
  }
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let continuation: CheckedContinuation<Data, Error>

  init(continuation: CheckedContinuation<Data, Error>) {
    self.continuation = continuation
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
  ) {
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
