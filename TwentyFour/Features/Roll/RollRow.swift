import Supabase
import SwiftUI

struct RollRow: View {
  let roll: Roll
  @State private var coverURL: URL?

  private var isDeveloped: Bool { roll.status == "developed" }
  private var members: [Member] { roll.members ?? [] }

  private func loadCover() async {
    guard isDeveloped else { return }

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

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(roll.name)
          .font(.system(size: 17, weight: .bold, design: .rounded))
          .foregroundStyle(coverURL == nil ? Theme.ink : .white)
        Text(roll.details)
          .font(.system(size: 13, design: .rounded))
          .foregroundStyle(coverURL == nil ? Theme.ink.opacity(0.6) : .white.opacity(0.85))
        MemberAvatars(
          members: members,
          textColor: coverURL == nil ? Theme.ink.opacity(0.6) : .white.opacity(0.85)
        )
        .padding(.top, 4)
      }
      Spacer()

      VStack(alignment: .trailing, spacing: 6) {
        Text(isDeveloped ? "DEVELOPED" : "IN CAMERA")
          .font(.system(size: 10, weight: .bold, design: .rounded))
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(isDeveloped ? Theme.ink : Theme.accent)
          .foregroundStyle(.white)
          .clipShape(Capsule())

        Text("\(roll.framesTaken) / \(roll.frameCount)")
          .font(.system(size: 13, design: .monospaced))
          .foregroundStyle(coverURL == nil ? Theme.ink : .white)
      }
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 16)
    .background {
      if let coverURL {
        AsyncImage(url: coverURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Theme.ink
        }
        .overlay(Color.black.opacity(0.3))
        .overlay(
          LinearGradient(
            colors: [.black.opacity(0.65), .black.opacity(0.15)],
            startPoint: .leading, endPoint: .trailing)
        )
      } else {
        Color.white
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .task { await loadCover() }
  }
}
