import SwiftUI

// The mockup's card: paper, big title, and a mosaic of 6 photos in mixed sizes.
struct MosaicCard: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  private let gap: CGFloat = 6

  private func photo(_ i: Int) -> some View {
    RecapPhoto(image: i < photos.count ? photos[i] : nil, number: i < photos.count ? i + 1 : nil)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      RecapHeader(roll: roll, peopleCount: peopleCount)

      VStack(spacing: gap) {
        HStack(spacing: gap) {
          photo(0).frame(width: 203, height: 136)
          photo(1).frame(width: 103, height: 136)
        }
        HStack(spacing: gap) {
          photo(2).frame(width: 120, height: 158)
          photo(3).frame(width: 186, height: 158)
        }
        HStack(spacing: gap) {
          photo(4).frame(width: 120, height: 110)
          photo(5).frame(width: 186, height: 110)
        }
      }
      .padding(.top, 14)

      Spacer(minLength: 0)

      RecapFooter()
    }
    .padding(24)
    .frame(width: 360, height: 640, alignment: .topLeading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }
}
