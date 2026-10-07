import SwiftUI

struct CameraView: View {
  let roll: Roll
  @State private var camera = CameraController()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      CameraPreview(session: camera.session).ignoresSafeArea()

      VStack {
        HStack {
          Text(roll.name).font(.headline)
          Spacer()
          Button { dismiss()} label: {Image(systemName: "xmark")}
        }
        Spacer()
        Text("\(roll.framesTaken) / \(roll.frameCount)")
        Button {} label: {
          Circle().fill(.white).frame(width: 72, height: 72)
        }
      }
      .foregroundStyle(.white)
      .padding()
    }
    .task {await camera.start()}
    .onDisappear {camera.stop()}
  }
}