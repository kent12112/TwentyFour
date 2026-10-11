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
  private var current: Roll { latest ?? roll}
  let roll: Roll
  var body: some View {
    VStack(spacing: 16) {
      if current.status == "developed" {
        ScrollView {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(frames) { frame in
            VStack(spacing: 4){
              AsyncImage(url: photoURLs[frame.id]) {
                image in image.resizable().scaledToFill()
              } placeholder: {
                Rectangle().fill(.gray.opacity(0.2))
              }
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
        Text(String(current.framesTaken) + "/" + String(current.frameCount))
        Button("Shoot") {
          showingCamera = true
        }
        Button("Invite") {
          showingInvite = true
        }
      }
    }
    .navigationTitle(current.name)
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
}