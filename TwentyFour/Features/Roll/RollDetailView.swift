import SwiftUI
import Supabase

struct RollDetailView: View {
  @State private var showingInvite = false
  @State private var showingCamera = false
  @State private var latest: Roll?
  @State private var frames: [Frame] = []
  @State private var photoURLs: [UUID: URL] = [:]
  @State private var names: [UUID: String] = [:]
  @State private var selectedFrame: Frame?
  @State private var recapPhotos: [UIImage] = []

  private var current: Roll { latest ?? roll}
  private var recapImage: Image? {
    let renderer = ImageRenderer(content: RecapCardView(
      roll: current,
      photos: recapPhotos,
      peopleCount: names.count
    ))
    renderer.scale = 3
    guard let uiImage = renderer.uiImage else { return nil }
    return Image(uiImage: uiImage)
  }
  let roll: Roll
  var body: some View {
    VStack(spacing: 16) {
      if current.status == "developed" {
        if !recapPhotos.isEmpty, let recapImage {
          ShareLink(item: recapImage, preview: SharePreview(current.name, image: recapImage)) {
            Label("Share recap", systemImage: "square.and.arrow.up")
          }
        }
        ScrollView {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(frames) { frame in
            VStack(spacing: 4){
              AsyncImage(url: photoURLs[frame.id]) {
                image in image.resizable().scaledToFill()
              } placeholder: {
                Rectangle().fill(.gray.opacity(0.2))
              }
              .frame(minWidth: 0, maxWidth: .infinity)
              .frame(height: 160)
              .clipped()

              Text("\(frame.frameNumber) / \(current.frameCount)")
                .font(.caption.monospacedDigit())
              Text(names[frame.photographerId ?? UUID()] ?? "Unknown")
                .font(.caption2)
            }
            .onTapGesture {
              selectedFrame = frame
            }
            } 
          }
          .padding()
        }
      }else {
        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading, spacing: 4) {
            Text(current.name)
              .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(current.details)
              .font(.system(size: 13, design: .rounded))
              .foregroundStyle(Theme.ink.opacity(0.6))
          }
          Spacer()
          VStack(spacing: 4) {
            Text("\(current.framesTaken)")
               .font(.system(size: 96, weight: .bold, design: .monospaced))
            Text("of \(current.frameCount) shots")
              .font(.system(size: 13, design: .rounded))
              .foregroundStyle(Theme.ink.opacity(0.6))
            HStack(spacing: 3) {
              ForEach(0..<current.frameCount, id: \.self) { i in 
                RoundedRectangle(cornerRadius: 2)
                  .fill(i < current.framesTaken ? Theme.ink : Theme.ink.opacity(0.15))
                  .frame(height: 24)
              }
            }
            .padding(.top, 24)
          }
          .frame(maxWidth: .infinity)
          Spacer()
          VStack(spacing: 12) {
            Text("Develops when the roll is full.")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.6))
            .padding(.bottom, 4)
            Button {
              showingCamera = true
            } label: { 
              Label("Shoot", systemImage: "camera.fill")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 12))
            }
            Button {
              showingInvite = true
            } label: {
                Text("Invite friends")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.ink, lineWidth: 1.5)
                )
            }
          }
        }
        .buttonStyle(.plain)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    }
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
    .navigationTitle(current.status == "developed" ? current.name : "")
    .navigationBarTitleDisplayMode(.inline)
    .task { await reload() }
    .sheet(isPresented: $showingInvite){
        InviteView(roll: current)
      }  
    .fullScreenCover(isPresented: $showingCamera, onDismiss: {
      Task { await reload() }
    }) {
      CameraView(roll: current)
    }
    .fullScreenCover(item: $selectedFrame) {
      frame in FrameViewer(frames: frames, photoURLs: photoURLs, names: names, startID: frame.id)
    }
  }
  private func reload() async {
    do {
      latest = try await SupabaseClient.shared
        .from("rolls")
        .select()
        .eq("id", value: roll.id)
        .single()
        .execute()
        .value
      if latest?.status == "developed" {
        await loadFrames()
      }
    } catch {
      print("Failed to reload roll:", error)
    }
  }
  private func loadFrames() async {
    do {
      frames = try await SupabaseClient.shared
        .from("frames")
        .select()
        .eq("roll_id", value: roll.id)
        .order("frame_number")
        .execute()
        .value
      await loadPhotoURLs()
      await loadNames()
      await loadRecapPhotos()
    } catch {
      print("Failed to reload roll:", error)
    }
  }
  private func loadPhotoURLs() async {
    for frame in frames {
      guard let path = frame.storagePath else { continue }
      do {
        let url = try await SupabaseClient.shared.storage
          .from("frames")
          .createSignedURL(path: path, expiresIn: 3600)
        photoURLs[frame.id] = url
      } catch {
        print("No URL for frame \(frame.frameNumber):", error)
      }
    }
  }
  private func loadNames() async {
    let ids = Array(Set(frames.compactMap { $0.photographerId}))
    do {
      let profiles: [Profile] = try await SupabaseClient.shared
        .from("profiles")
        .select()
        .in("id", values: ids)
        .execute()
        .value
      for profile in profiles {
        names[profile.id] = profile.displayName
      }
    } catch {print("Failed to load names:", error)}
  }

  private func loadRecapPhotos() async {
    var images: [UIImage] = []
    for frame in frames.prefix(9) {
      guard let url = photoURLs[frame.id] else {continue}
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let image = UIImage(data: data) {
          images.append(image)
        }
      } catch {
        print("Recap photo \(frame.frameNumber) failed:", error)
      }
    }
    recapPhotos = images
  }
}