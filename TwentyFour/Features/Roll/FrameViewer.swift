import SwiftUI

struct FrameViewer: View {
  let frames: [Frame]
  let photoURLs: [UUID: URL]
  let names: [UUID: String]
  @State private var currentID: UUID
  @State private var savedIDs: Set<UUID> = []
  @Environment(\.dismiss) private var dismiss

  init(frames: [Frame], photoURLs: [UUID: URL], names: [UUID: String], startID: UUID) {
    self.frames = frames
    self.photoURLs = photoURLs
    self.names = names
    _currentID = State(initialValue: startID)
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.black.ignoresSafeArea()

      TabView(selection: $currentID) {
        ForEach(frames) {
          frame in
          ZStack(alignment: .bottom) {
            AsyncImage(url: photoURLs[frame.id]) {
              image in
              image.resizable().scaledToFit()
            } placeholder: {
              ProgressView()
                .tint(.white)
            }

            VStack(spacing: 6) {
              Text(String(format: "%02d / %d", frame.frameNumber, frames.count))
                .font(Theme.mono(11, .medium))
                .foregroundStyle(Theme.stamp)
              Text(names[frame.photographerId ?? UUID()] ?? "Unknown")
                .font(Theme.sans(17, .medium))
              Text(frame.takenAt.formatted(date: .abbreviated, time: .shortened))
                .metaStyle(9, color: .white.opacity(0.6))
            }
            .foregroundStyle(.white)
            .padding(.bottom, 40)
          }
          .tag(frame.id)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))

      HStack(spacing: 4) {
        Button {
          Task { await saveCurrent() }
        } label: {
          Image(systemName: savedIDs.contains(currentID) ? "checkmark" : "arrow.down.to.line")
            .font(.system(size: 18, weight: .light))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .disabled(savedIDs.contains(currentID))

        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 18, weight: .light))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
      }
      .padding()
    }
  }

  private func saveCurrent() async {
    guard let url = photoURLs[currentID] else { return }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let image = UIImage(data: data) else { return }
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
      savedIDs.insert(currentID)
    } catch {
      print("Save failed:", error)
    }
  }
}
