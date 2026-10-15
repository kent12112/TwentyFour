import SwiftUI

struct MemberAvatars: View {
  let members: [Member]
  var textColor: Color = Theme.ink.opacity(0.6)

  var body: some View {
    HStack(spacing: -8) {
          ForEach(members.prefix(3), id: \.profile.id) { member in
            Text(String(member.profile.displayName.prefix(1)))
              .font(.system(size: 11, weight: .bold, design: .rounded))
              .frame(width: 24, height: 24)
              .background(Theme.ink, in: Circle())
              .foregroundStyle(.white)
              .overlay(Circle().stroke(Theme.paper, lineWidth: 2))
          }
          if members.count > 3 {
            Text("+\(members.count-3)")
              .foregroundStyle(textColor)
              .font(.system(size: 12, design: .rounded))
              .padding(.leading, 12)
          }
      }
  }
}