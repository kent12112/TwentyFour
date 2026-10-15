import SwiftUI

struct HeroCard: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      RecapWordmark()

      Spacer()

      if let hero = photos.first {
        Color.clear
          .aspectRatio(1, contentMode: .fit)
          .overlay {
            Image(uiImage: hero)
              .resizable()
              .scaledToFill()
          }
          .clipped()
          .overlay(alignment: .bottomTrailing) {
            Text(roll.stampText)
              .font(.custom("DINCondensed-Bold", size: 16))
              .foregroundStyle(Theme.stamp)
              .padding(10)
          }
          .padding(10)
          .background(.white)
          .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
      }

      Spacer()

      RecapFooter(roll: roll, peopleCount: peopleCount, secondary: Theme.ink.opacity(0.6))
    }
    .padding(24)
    .frame(width: 360, height: 640, alignment: .leading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }
}
