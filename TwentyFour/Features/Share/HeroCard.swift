import SwiftUI

// One photo, big, in a white print border, centered between header and footer.
struct HeroCard: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      RecapHeader(roll: roll, peopleCount: peopleCount)

      Spacer(minLength: 16)

      if let hero = photos.first {
        VStack(alignment: .leading, spacing: 8) {
          RecapPhoto(image: hero)
            .aspectRatio(shape(of: hero), contentMode: .fit)
            .overlay(alignment: .bottomTrailing) {
              Text(roll.stampText)
                .font(Theme.mono(9))
                .foregroundStyle(Theme.stamp)
                .padding(8)
            }
          Text(String(format: "01 / %d", roll.frameCount))
            .font(Theme.mono(7))
            .foregroundStyle(Theme.muted)
        }
        .padding(10)
        .background(.white)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.horizontal, 12)
      }

      Spacer(minLength: 16)

      RecapFooter()
    }
    .padding(24)
    .frame(width: 360, height: 640, alignment: .topLeading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }

  // the photo's own shape, kept between tall portrait (2:3) and wide landscape (3:2) so it fits the card
  private func shape(of image: UIImage) -> CGFloat {
    let ratio = image.size.width / max(image.size.height, 1)
    return min(max(ratio, 2.0 / 3.0), 3.0 / 2.0)
  }
}
