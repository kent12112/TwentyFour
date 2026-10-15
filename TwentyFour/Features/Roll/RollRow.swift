import Supabase
import SwiftUI

struct RollRow: View {
  let roll: Roll
  @State private var coverURL: URL?

  private var members: [Member] { roll.members ?? [] }

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      cover

      VStack(alignment: .leading, spacing: 6) {
        Text(roll.name)
          .font(Theme.sans(17, .medium))
          .foregroundStyle(Theme.ink)
          .lineLimit(1)
        Text(roll.metaLine)
          .metaStyle(9)
        Spacer(minLength: 0)
        MemberAvatars(members: members)
      }

      Spacer(minLength: 0)

      VStack(alignment: .trailing) {
        Text("\(roll.framesTaken)/\(roll.frameCount)")
          .font(Theme.mono(11, .medium))
          .foregroundStyle(Theme.ink)
        Spacer(minLength: 0)
        HStack(spacing: 5) {
          Circle()
            .fill(roll.isDeveloped ? Theme.ink : Theme.accent)
            .frame(width: 5, height: 5)
          Text(roll.isDeveloped ? "Developed" : "In camera")
            .metaStyle(8)
        }
        .padding(.bottom, 4)
      }
    }
    .frame(height: 96)
    .padding(.vertical, 14)
    .contentShape(Rectangle())
    .task { await loadCover() }
  }

  // developed: the roll's cover (first photo) · in camera: a dark film tile, since photos stay hidden
  private var cover: some View {
    ZStack {
      Theme.film
      if let coverURL {
        AsyncImage(url: coverURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.clear
        }
      } else if !roll.isDeveloped {
        Image(systemName: "camera")
          .font(.system(size: 18, weight: .light))
          .foregroundStyle(Theme.paper.opacity(0.5))
      }
    }
    .frame(width: 78, height: 96)
    .clipped()
  }

  private func loadCover() async {
    guard roll.isDeveloped, coverURL == nil else { return }
    do {
      let firstFrames: [Frame] = try await SupabaseClient.shared
        .from("frames")
        .select()
        .eq("roll_id", value: roll.id)
        .order("frame_number")
        .limit(1)
        .execute()
        .value
      guard let path = firstFrames.first?.storagePath else { return }
      coverURL = try await SupabaseClient.shared.storage
        .from("frames")
        .createSignedURL(path: path, expiresIn: 3600)
    } catch {
      print("Cover for \(roll.name) failed:", error)
    }
  }
}
