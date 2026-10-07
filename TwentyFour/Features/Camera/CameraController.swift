import AVFoundation
import Observation

@Observable
final class CameraController {
  let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
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