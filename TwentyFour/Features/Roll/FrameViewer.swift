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

            VStack(spacing: 2) {
              Text(names[frame.photographerId ?? UUID()] ?? "Unknown")
                .font(.system(size: 17, weight: .bold, design: .rounded))
              Text(frame.takenAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
              Text("\(frame.frameNumber) / \(frames.count)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.stamp)
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
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .disabled(savedIDs.contains(currentID))

        Button {
          dismiss()
        } label: {  // ← the close button, back in
          Image(systemName: "xmark")
            .font(.title2)
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
