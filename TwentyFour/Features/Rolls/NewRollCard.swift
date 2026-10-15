import SwiftUI

struct NewRollCard: View {
  var body: some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Create a new roll")
          .font(.system(size: 17, weight: .bold, design: .rounded))
        Text("24 shots · invite your friends")
          .font(.system(size: 13, design: .rounded))
          .foregroundStyle(.white.opacity(0.6))
      }
      Spacer()
      Image(systemName: "plus.circle.fill")
        .font(.system(size: 30))
        .foregroundStyle(.white)
    }
    .padding(20)
    .foregroundStyle(.white)
    .background(
      Theme.ink, in: RoundedRectangle(cornerRadius: 16)
    )
  }
}

#Preview {
  NewRollCard()
    .padding()
}
