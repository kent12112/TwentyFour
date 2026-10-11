import SwiftUI

struct FrameViewer: View {
  let frames: [Frame]
  let photoURLs: [UUID: URL]
  let names: [UUID: String]
  @State private var currentID: UUID
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
          frame in ZStack(alignment: .bottom) {
            AsyncImage(url: photoURLs[frame.id]) {
              image in image.resizable().scaledToFit()
            } placeholder: {
              ProgressView()
            }

            VStack(spacing: 2) {
              Text(names[frame.photographerId ?? UUID()] ?? "Unknown")
                .font(.headline)
              Text(frame.takenAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
              Text("\(frame.frameNumber) / \(frames.count)")
                .font(.caption.monospacedDigit())
            }
            .foregroundStyle(.white)
            .padding(.bottom, 40)
          }
          .tag(frame.id)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))

      Button { dismiss() } label: {
        Image(systemName: "xmark")
          .font(.title2)
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .padding()
    }
  }
}