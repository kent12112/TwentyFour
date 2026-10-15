import SwiftUI

struct RecapEditorView: View {
  // passed in from RollDetailView
  let roll: Roll
  let frames: [Frame]
  let photoURLs: [UUID: URL]
  let peopleCount: Int

  // owned by this screen
  @State private var images: [UUID: UIImage] = [:]
  @State private var selected: [UUID] = []
  @State private var showingRecap = false
  @Environment(\.dismiss) private var dismiss

  private let maxPhotos = 9

  private var selectedImages: [UIImage] {
    selected.compactMap { images[$0] }
  }
  private var renderedImage: Image? {
    let renderer = ImageRenderer(
      content: RecapCardView(
        roll: roll,
        photos: selectedImages,
        peopleCount: peopleCount
      )
    )
    renderer.scale = 3
    guard let uiImage = renderer.uiImage else { return nil }
    return Image(uiImage: uiImage)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Theme.paper.ignoresSafeArea()

        VStack(spacing: 16) {
          RecapCardView(roll: roll, photos: selectedImages, peopleCount: peopleCount)
            .scaleEffect(0.5)
            .frame(width: 180, height: 320)
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
          Text("Pick up to \(maxPhotos) · \(selected.count) selected")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.6))
          ScrollView {
            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4
            ) {
              ForEach(frames) { frame in
                let number = selected.firstIndex(of: frame.id)

                Color.clear
                  .aspectRatio(1, contentMode: .fit)
                  .overlay {
                    if let image = images[frame.id] {
                      Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    } else {
                      Theme.ink.opacity(0.08)
                    }
                  }
                  .clipped()
                  .opacity(number == nil ? 0.5 : 1)
                  .overlay(alignment: .topTrailing) {
                    if let number {
                      Text("\(number + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Theme.accent, in: Circle())
                        .padding(4)
                    }
                  }
                  .contentShape(Rectangle())
                  .onTapGesture { toggle(frame.id) }
              }
            }
            .padding(.horizontal, 16)
          }
        }
        .padding(.top, 8)
      }
      .navigationTitle("Recap")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          if !selected.isEmpty, let image = renderedImage {
            ShareLink(item: image, preview: SharePreview(roll.name, image: image)) {
              Text("Share")
                .bold()
            }
          }
        }
      }

    }
    .tint(Theme.ink)
    .task { await loadImages() }
  }

  private func loadImages() async {
    for frame in frames {
      guard let url = photoURLs[frame.id] else { continue }
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { continue }
        images[frame.id] = image
        if selected.count < maxPhotos {
          selected.append(frame.id)
        }
      } catch {
        print("Recap photo \(frame.frameNumber) failed:", error)
      }
    }
  }
  private func toggle(_ id: UUID) {
    guard images[id] != nil else { return }
    if let index = selected.firstIndex(of: id) {
      selected.remove(at: index)
    } else if selected.count < maxPhotos {
      selected.append(id)
    }
  }
}
