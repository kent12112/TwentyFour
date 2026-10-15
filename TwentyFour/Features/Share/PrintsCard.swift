import SwiftUI

struct PrintsCard: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  // two staggered columns: left at the top/middle/bottom, right in between,
  // so every photo stays visible and neighbors only overlap at the edges
  private let layout: [(x: CGFloat, y: CGFloat, angle: Double)] = [
    (-52, -135, -4),
    (52, -68, 3),
    (-52, 0, 2),
    (52, 68, -3),
    (-52, 135, 4),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      RecapWordmark()

      ZStack {
        ForEach(0..<min(photos.count, layout.count), id: \.self) { i in
          printView(photos[i])
            .rotationEffect(.degrees(layout[i].angle))
            .offset(x: layout[i].x, y: layout[i].y)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      RecapFooter(roll: roll, peopleCount: peopleCount, secondary: Theme.ink.opacity(0.6))
    }
    .padding(24)
    .frame(width: 360, height: 640)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }

  private func printView(_ image: UIImage) -> some View {
    Color.clear
      .frame(width: 124, height: 124)
      .overlay {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      }
      .clipped()
      .overlay(alignment: .bottomTrailing) {
        Text(roll.stampText)
          .font(.custom("DINCondensed-Bold", size: 11))
          .foregroundStyle(Theme.stamp)
          .padding(6)
      }
      .padding(8)
      .padding(.bottom, 20)
      .background(.white)
      .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
  }
}
