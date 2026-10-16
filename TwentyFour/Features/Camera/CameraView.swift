import Supabase
import SwiftUI

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

      // dark fades at top and bottom so white text reads on any photo
      VStack(spacing: 0) {
        LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
          .frame(height: 150)
        Spacer()
        LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
          .frame(height: 300)
      }
      .ignoresSafeArea()
      .allowsHitTesting(false)

      // faint focus square
      Rectangle()
        .stroke(.white.opacity(0.45), lineWidth: 1)
        .frame(width: 54, height: 54)
        .allowsHitTesting(false)

      VStack(spacing: 0) {
        topBar
        Spacer()
        Text("\(framesTaken)  /  \(roll.frameCount)")
          .font(.system(size: 13, weight: .medium, design: .monospaced))
          .padding(.bottom, 18)
        controls
      }
      .foregroundStyle(.white)
    }
    .sensoryFeedback(.impact(weight: .medium), trigger: isShooting) { _, started in started }
    .task {
      framesTaken = roll.framesTaken
      await camera.start()
      await listenForCounter()
    }
    .onDisappear {
      camera.stop()
    }
  }

  // ✕ · ROLL NAME · ⚡
  private var topBar: some View {
    HStack {
      Button { dismiss() } label: {
        Image(systemName: "xmark")
          .font(.system(size: 18, weight: .light))
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      Spacer()
      Text(roll.name)
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .textCase(.uppercase)
        .tracking(1.5)
        .lineLimit(1)
      Spacer()
      Button { camera.isFlashOn.toggle() } label: {
        Image(systemName: camera.isFlashOn ? "bolt" : "bolt.slash")
          .font(.system(size: 18, weight: .light))
          .foregroundStyle(camera.isFlashOn ? Color.yellow : Color.white)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
    }
    .padding(.horizontal, 12)
  }

  // AE · shutter · flip
  private var controls: some View {
    HStack {
      roundButton(active: camera.isExposureLocked) {
        Text("AE")
          .font(.system(size: 11, weight: .semibold, design: .monospaced))
      } action: {
        camera.toggleExposureLock()
      }

      Spacer()

      Button {
        Task { await shoot() }
      } label: {
        ZStack {
          Circle()
            .stroke(.white, lineWidth: 3)
            .frame(width: 80, height: 80)
          Circle()
            .fill(.white)
            .frame(width: 66, height: 66)
            .scaleEffect(isShooting ? 0.86 : 1)
        }
      }
      .disabled(isShooting)
      .animation(.easeOut(duration: 0.15), value: isShooting)

      Spacer()

      roundButton(active: false) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(.system(size: 18, weight: .light))
      } action: {
        camera.flip()
      }
      .disabled(isShooting)
    }
    .padding(.horizontal, 40)
    .padding(.bottom, 28)
  }

  // a see-through dark circle; yellow content when active (e.g. AE locked)
  private func roundButton<Content: View>(
    active: Bool,
    @ViewBuilder content: () -> Content,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      content()
        .foregroundStyle(active ? Color.yellow : Color.white)
        .frame(width: 46, height: 46)
        .background(.black.opacity(0.35), in: Circle())
        .overlay(Circle().stroke(.white.opacity(active ? 0.0 : 0.12), lineWidth: 1))
    }
  }

  private func shoot() async {
    isShooting = true
    defer { isShooting = false }
    let frame: Frame
    do {
      frame = try await SupabaseClient.shared
        .rpc("claim_frame", params: ["p_roll_id": roll.id])
        .execute()
        .value
    } catch {
      print("Claim failed:", error)
      return
    }

    do {
      let data = try await camera.capturePhoto()
      let processed = FilmProcessor.process(data) ?? data
      try UploadQueue.shared.add(frame: frame, data: processed)
    } catch {
      // no photo was saved, so give the frame number back right away
      print("Shoot failed, releasing frame \(frame.frameNumber):", error)
      _ = try? await SupabaseClient.shared
        .rpc("release_frame", params: ["p_frame_id": frame.id])
        .execute()
      return
    }

    framesTaken += 1
    print("Shot frame", frame.frameNumber, "-> queued for upload")

    // tell the server a real photo exists, so its frame is never released
    _ = try? await SupabaseClient.shared
      .rpc("mark_captured", params: ["p_frame_id": frame.id])
      .execute()
    Task { await UploadQueue.shared.processAll() }
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
