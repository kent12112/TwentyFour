import SwiftUI

// Up to 5 white-bordered prints in two staggered columns, every photo visible.
struct PrintsCard: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  // offset from the center of the photo area, and a small tilt
  private let layout: [(x: CGFloat, y: CGFloat, angle: Double)] = [
    (-52, -128, -3),
    (52, -64, 2.5),
    (-52, 0, 1.5),
    (52, 64, -2.5),
    (-52, 128, 3),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      RecapHeader(roll: roll, peopleCount: peopleCount)

      ZStack {
        ForEach(0..<min(photos.count, layout.count), id: \.self) { i in
          printView(photos[i], number: i + 1)
            .rotationEffect(.degrees(layout[i].angle))
            .offset(x: layout[i].x, y: layout[i].y)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      RecapFooter()
    }
    .padding(24)
    .frame(width: 360, height: 640, alignment: .topLeading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }

  private func printView(_ image: UIImage, number: Int) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      RecapPhoto(image: image)
        .frame(width: 118, height: 118)
        .overlay(alignment: .bottomTrailing) {
          Text(roll.stampText)
            .font(Theme.mono(6))
            .foregroundStyle(Theme.stamp)
            .padding(4)
        }
      Text(String(format: "%02d / %d", number, roll.frameCount))
        .font(Theme.mono(6))
        .foregroundStyle(Theme.muted)
    }
    .padding(6)
    .padding(.bottom, 2)
    .background(.white)
    .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
  }
}
