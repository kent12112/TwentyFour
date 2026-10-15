import SwiftUI

struct MemberAvatars: View {
  let members: [Member]
  var textColor: Color = Theme.muted
  var ringColor: Color = Theme.paper

  var body: some View {
    HStack(spacing: -6) {
      ForEach(members.prefix(3), id: \.profile.id) { member in
        Text(initials(member.profile.displayName))
          .font(Theme.sans(8, .semibold))
          .foregroundStyle(.white)
          .frame(width: 22, height: 22)
          .background(color(for: member.profile.id), in: Circle())
          .overlay(Circle().stroke(ringColor, lineWidth: 1.5))
      }
      if members.count > 3 {
        Text("+\(members.count - 3)")
          .font(Theme.mono(10))
          .foregroundStyle(textColor)
          .padding(.leading, 10)
      }
    }
  }

  // "Emily" → "EM", "Ken to" → "KE"
  private func initials(_ name: String) -> String {
    String(name.replacingOccurrences(of: " ", with: "").prefix(2)).uppercased()
  }

  // the same person always gets the same color
  private func color(for id: UUID) -> Color {
    let firstByte = Int(id.uuid.0)
    return Theme.avatarColors[firstByte % Theme.avatarColors.count]
  }
}
