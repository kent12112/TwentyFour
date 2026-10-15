import SwiftUI

struct NewRollCard: View {
  var body: some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Create a new roll")
          .font(Theme.sans(16, .medium))
          .foregroundStyle(.white)
        Text("24 frames · invite friends")
          .metaStyle(9, color: .white.opacity(0.55))
      }
      Spacer()
      Image(systemName: "plus")
        .font(.system(size: 16, weight: .light))
        .foregroundStyle(Theme.ink)
        .frame(width: 36, height: 36)
        .background(.white, in: Circle())
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 20)
    .background(Theme.ink)
  }
}

#Preview {
  NewRollCard()
    .padding()
}
