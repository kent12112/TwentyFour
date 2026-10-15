import Supabase
import SwiftUI

struct RollDetailView: View {
  @State private var showingInvite = false
  @State private var showingCamera = false
  @State private var latest: Roll?
  @State private var frames: [Frame] = []
  @State private var photoURLs: [UUID: URL] = [:]
  @State private var names: [UUID: String] = [:]
  @State private var selectedFrame: Frame?
  @State private var showingRecap = false

  private var current: Roll { latest ?? roll } 
  let roll: Roll
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header

      if current.isDeveloped {
        ScrollView {
          DevelopedGrid(
            frames: frames,
            photoURLs: photoURLs,
            frameCount: current.frameCount
          ) { frame in
            selectedFrame = frame
          }
        }
      } else {
        inCamera
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarRole(.editor)
    .toolbarBackground(Theme.paper, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("TwentyFour")
          .font(Theme.sans(13, .bold))
          .textCase(.uppercase)
          .tracking(0.5)
      }
      ToolbarItem(placement: .topBarTrailing) {
        if current.isDeveloped {
          Button {
            showingRecap = true
          } label: {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 16, weight: .light))
          }
        }
      }
    }
    .task { await reload() }
    .sheet(isPresented: $showingInvite) {
      InviteView(roll: current)
        .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $showingRecap) {
      RecapEditorView(
        roll: current,
        frames: frames,
        photoURLs: photoURLs,
        peopleCount: names.count
      )
    }
    .fullScreenCover(
      isPresented: $showingCamera,
      onDismiss: {
        Task { await reload() }
      }
    ) {
      CameraView(roll: current)
    }
    .fullScreenCover(item: $selectedFrame) {
      frame in FrameViewer(frames: frames, photoURLs: photoURLs, names: names, startID: frame.id)
    }
  }
  private var peopleCount: Int {
    max(current.members?.count ?? 0, names.count)
  }

  // big uppercase name, meta line on both sides, divider
  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(current.name)
        .font(Theme.sans(28))
        .textCase(.uppercase)
        .lineLimit(2)
      HStack {
        Text(current.metaLine)
        Spacer()
        Text("\(current.frameCount) frames · \(peopleCount) \(peopleCount == 1 ? "person" : "people")")
      }
      .metaStyle(9)
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 20)
    .overlay(alignment: .bottom) {
      Rectangle().fill(Theme.line).frame(height: 1)
    }
  }

  // while shooting: big counter, frame bars, members, buttons
  private var inCamera: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
      VStack(spacing: 10) {
        Text(String(format: "%02d", current.framesTaken))
          .font(Theme.mono(88, .medium))
        Text("of \(current.frameCount) frames")
          .metaStyle(10)
        HStack(spacing: 3) {
          ForEach(0..<current.frameCount, id: \.self) { i in
            Rectangle()
              .fill(i < current.framesTaken ? Theme.ink : Theme.line)
              .frame(height: 22)
          }
        }
        .padding(.top, 20)
        MemberAvatars(members: current.members ?? [])
          .padding(.top, 20)
      }
      .frame(maxWidth: .infinity)
      Spacer()
      VStack(spacing: 10) {
        Text("Develops when the roll is full")
          .metaStyle(9)
          .padding(.bottom, 6)
        Button {
          showingCamera = true
        } label: {
          Label("Shoot", systemImage: "camera")
            .font(Theme.sans(15, .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.ink)
        }
        Button {
          showingInvite = true
        } label: {
          Text("Invite friends")
            .font(Theme.sans(15, .medium))
            .frame(maxWidth: .infinity, minHeight: 52)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1))
            .contentShape(Rectangle())
        }
      }
    }
    .buttonStyle(.plain)
    .padding(24)
  }

  private func reload() async {
    do {
      latest = try await SupabaseClient.shared
        .from("rolls")
        .select("*, members:roll_members(profile:profiles(id, display_name, color))")
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
    let ids = Array(Set(frames.compactMap { $0.photographerId }))
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
    } catch { print("Failed to load names:", error) }
  }
}
  
 
