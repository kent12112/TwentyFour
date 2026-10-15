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
  @State private var template: RecapTemplate = .mosaic
  @State private var saved = false
  @State private var instagramProblem: InstagramStories.Problem?
  @Environment(\.dismiss) private var dismiss

  private var maxPhotos: Int { template.maxPhotos }

  private var selectedImages: [UIImage] {
    selected.compactMap { images[$0] }
  }

  private var card: RecapCardView {
    RecapCardView(roll: roll, photos: selectedImages, peopleCount: peopleCount, template: template)
  }

  // the card rendered at 3× = 1080×1920, the size of an Instagram story
  private func renderCard() -> UIImage? {
    let renderer = ImageRenderer(content: card)
    renderer.scale = 3
    return renderer.uiImage
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        card
          .scaleEffect(0.6)
          .frame(width: 216, height: 384)
          .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
          .padding(.top, 12)

        templateTabs
          .padding(.top, 18)

        Text("Pick up to \(maxPhotos) · \(selected.count) selected")
          .metaStyle(8)
          .padding(.top, 14)
          .padding(.bottom, 8)

        photoPicker

        bottomButtons
      }
      .background(Theme.paper)
      .foregroundStyle(Theme.ink)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Theme.paper, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
            .font(Theme.sans(15))
            .foregroundStyle(Theme.muted)
        }
        ToolbarItem(placement: .principal) {
          Text("Share")
            .font(Theme.sans(16, .medium))
        }
        ToolbarItem(placement: .confirmationAction) {
          if !selected.isEmpty, let image = renderCard() {
            let picture = Image(uiImage: image)
            ShareLink(item: picture, preview: SharePreview(roll.name, image: picture)) {
              HStack(spacing: 4) {
                Text("Export")
                Image(systemName: "arrow.up.right")
                  .font(.system(size: 11, weight: .medium))
              }
              .font(Theme.sans(15, .medium))
            }
          }
        }
      }
      .onChange(of: template) {
        if selected.count > maxPhotos {
          selected = Array(selected.prefix(maxPhotos))
        }
        saved = false
      }
      .onChange(of: selected) { saved = false }
      .alert(
        instagramProblem == .notInstalled ? "Instagram isn't installed" : "Instagram sharing isn't set up",
        isPresented: Binding(get: { instagramProblem != nil }, set: { if !$0 { instagramProblem = nil } })
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(
          instagramProblem == .notInstalled
            ? "Install Instagram, or use Export to share another way."
            : "Add a Meta App ID to FACEBOOK_APP_ID in Secrets.xcconfig."
        )
      }
    }
    .tint(Theme.ink)
    .task(id: photoURLs.count) { await loadImages() }
  }

  // MOSAIC  FILM  PRINTS  HERO — underlined when chosen
  private var templateTabs: some View {
    HStack(spacing: 22) {
      ForEach(RecapTemplate.allCases) { option in
        Button {
          template = option
        } label: {
          VStack(spacing: 5) {
            Text(option.title)
              .font(Theme.mono(10, template == option ? .medium : .regular))
              .textCase(.uppercase)
              .tracking(0.8)
              .foregroundStyle(template == option ? Theme.ink : Theme.muted)
            Rectangle()
              .fill(template == option ? Theme.ink : .clear)
              .frame(height: 1)
          }
          .fixedSize()
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var photoPicker: some View {
    ScrollView {
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4
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
                Theme.line
              }
            }
            .clipped()
            .opacity(number == nil ? 0.45 : 1)
            .overlay(alignment: .topTrailing) {
              if let number {
                Text("\(number + 1)")
                  .font(Theme.mono(9, .medium))
                  .foregroundStyle(.white)
                  .frame(width: 18, height: 18)
                  .background(Theme.ink)
                  .padding(3)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture { toggle(frame.id) }
        }
      }
      .padding(.horizontal, 24)
    }
  }

  // ⬇ save · Share to Instagram Story
  private var bottomButtons: some View {
    HStack(spacing: 10) {
      Button {
        guard let image = renderCard() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        saved = true
      } label: {
        Image(systemName: saved ? "checkmark" : "arrow.down.to.line")
          .font(.system(size: 16, weight: .light))
          .frame(width: 54, height: 54)
          .overlay(Rectangle().stroke(Theme.line, lineWidth: 1))
          .contentShape(Rectangle())
      }

      Button {
        guard let image = renderCard() else { return }
        instagramProblem = InstagramStories.share(image)
      } label: {
        HStack(spacing: 10) {
          Image(systemName: "camera")
            .font(.system(size: 15, weight: .light))
          Text("Share to Instagram Story")
            .font(Theme.sans(15, .medium))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(Theme.ink)
      }
    }
    .buttonStyle(.plain)
    .disabled(selected.isEmpty)
    .opacity(selected.isEmpty ? 0.4 : 1)
    .padding(.horizontal, 24)
    .padding(.top, 12)
    .padding(.bottom, 8)
  }

  private func loadImages() async {
    for frame in frames {
      if images[frame.id] != nil { continue }
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
    } else if maxPhotos == 1 {
      selected = [id]  // Hero: tapping another photo swaps it in
    }
  }
}
