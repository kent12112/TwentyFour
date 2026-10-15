import SwiftUI

// Dark film base with sprocket rows, 3 frames per row, orange frame numbers.
struct FilmStripCard: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  private var rowStarts: [Int] {
    Array(stride(from: 0, to: max(photos.count, 1), by: 3))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      RecapHeader(roll: roll, peopleCount: peopleCount, dark: true)

      VStack(spacing: 0) {
        ForEach(rowStarts, id: \.self) { start in
          filmRow(start: start)
        }
      }
      .padding(.top, 14)

      Spacer(minLength: 0)

      RecapFooter(dark: true)
    }
    .padding(24)
    .frame(width: 360, height: 640, alignment: .topLeading)
    .background(Theme.film)
    .foregroundStyle(Theme.paper)
  }

  private var sprockets: some View {
    HStack(spacing: 0) {
      ForEach(0..<16, id: \.self) { _ in
        Rectangle()
          .fill(Theme.paper.opacity(0.8))
          .frame(width: 7, height: 5)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, 6)
  }

  private func filmRow(start: Int) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      sprockets
      HStack(spacing: 4) {
        ForEach(start..<start + 3, id: \.self) { i in
          RecapPhoto(image: i < photos.count ? photos[i] : nil)
            .aspectRatio(4 / 3, contentMode: .fit)
            .opacity(i < photos.count ? 1 : 0)
        }
      }
      HStack(spacing: 4) {
        ForEach(start..<start + 3, id: \.self) { i in
          Text(i < photos.count ? String(format: "%02d ▸", i + 1) : "")
            .font(Theme.mono(7))
            .foregroundStyle(Theme.stamp)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}
