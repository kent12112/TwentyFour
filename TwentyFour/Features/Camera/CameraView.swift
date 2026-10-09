import SwiftUI
import Supabase

struct CameraView: View {
  let roll: Roll
  @State private var camera = CameraController()
  @State private var isShooting = false
  @State private var framesTaken = 0
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      CameraPreview(session: camera.session).ignoresSafeArea()

      VStack {
        HStack {
          Text(roll.name).font(.headline)
          Spacer()
          Button{ camera.isFlashOn.toggle() } label: {
            Image(systemName: camera.isFlashOn ? "bolt.fill" : "bolt.slash")
          }
          Button { dismiss()} label: {Image(systemName: "xmark")}
        }
        Spacer()
        Text("\(framesTaken) / \(roll.frameCount)")
        Button { Task { await shoot() } } label: {
          Circle().fill(.white).frame(width: 72, height: 72)
        }
        .disabled(isShooting)
      }
      .foregroundStyle(.white)
      .padding()
    }
    .task {
      framesTaken = roll.framesTaken
      await camera.start()
      await listenForCounter()
      }
    .onDisappear {
      camera.stop()}
  }

  private func shoot() async {
    isShooting = true
    defer { isShooting = false }
    do {
      let frame: Frame = try await SupabaseClient.shared
        .rpc("claim_frame", params: ["p_roll_id": roll.id])
        .execute()
        .value
      let data = try await camera.capturePhoto()
      let processed = FilmProcessor.process(data) ?? data
      let path = "\(roll.id.uuidString.lowercased())/\(frame.frameNumber).jpg"

      try UploadQueue.shared.add(frame: frame, storagePath: path, data: processed)
      framesTaken = frame.frameNumber

      Task { await UploadQueue.shared.processAll()}
      print("Shot frmae", frame.frameNumber, "-> queued for upload")
    } catch {
      print("Shoot failed:", error)
    }
  }

  private func listenForCounter() async {
    let channel = SupabaseClient.shared.channel("roll-\(roll.id)")
    let changes = channel.postgresChange(
      UpdateAction.self,
      schema: "public",
      table: "rolls",
      filter: .eq("id", value: roll.id)
    )
    do {
      try await channel.subscribeWithError()
    } catch {
      print("Realtime subscribe failed:", error)
      return
    }

    for await change in changes {
      if let newCount = change.record["frames_taken"]?.intValue {
        framesTaken = newCount
      }
    }
    await SupabaseClient.shared.removeChannel(channel)
  }
}

struct FinalizeParams: Encodable {
  let p_frame_id: UUID
  let p_storage_path: String
}