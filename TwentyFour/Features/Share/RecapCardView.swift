import SwiftUI

struct RecapCardView: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  private var rowStarts: [Int] {
    Array(stride(from: 0, to: photos.count, by: 3))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // header
      HStack {
        HStack(spacing: 6) {
          Text("TwentyFour")
            .font(.custom("ChalkboardSE-Bold", size: 22))
          Circle()
            .fill(Theme.accent)
            .frame(width: 7, height: 7)
        }
        Spacer()
        Text("\(roll.frameCount) EXP")
          .font(.custom("DINCondensed-Bold", size: 15))
          .foregroundStyle(Theme.stamp)
      }
      .padding(.bottom, 16)

      // film strip
      VStack(spacing: 0) {
        ForEach(rowStarts, id: \.self) { start in
          filmRow(start: start)
        }
      }

      Spacer()

      // footer
      VStack(alignment: .leading, spacing: 4) {
        Text(roll.name)
          .font(.custom("Futura-CondensedExtraBold", size: 40))
          .textCase(.uppercase)
        Text(roll.details)
          .font(.custom("DINCondensed-Bold", size: 16))
          .foregroundStyle(Theme.paper.opacity(0.6))
        Text("\(roll.framesTaken) shots · \(peopleCount) friends")
          .font(.custom("DINCondensed-Bold", size: 16))
          .foregroundStyle(Theme.paper.opacity(0.6))
        Text("shot together on TwentyFour")
          .font(.custom("Courier-Bold", size: 12))
          .foregroundStyle(Theme.stamp)
          .padding(.top, 8)
      }
    }
    .padding(24)
    .frame(width: 360, height: 640)
    .background(Theme.film)
    .foregroundStyle(Theme.paper)
  }

  private var sprockets: some View {
    HStack(spacing: 0) {
      ForEach(0..<14, id: \.self) { _ in
        RoundedRectangle(cornerRadius: 1.5)
          .fill(Theme.paper.opacity(0.85))
          .frame(width: 8, height: 6)
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
          if i < photos.count {
            Color.clear
              .aspectRatio(1, contentMode: .fit)
              .overlay {
                Image(uiImage: photos[i])
                  .resizable()
                  .scaledToFill()
              }
              .clipped()
          } else {
            Color.clear
              .aspectRatio(1, contentMode: .fit)
          }
        }
      }
      HStack(spacing: 4) {
        ForEach(start..<start + 3, id: \.self) { i in
          Text(i < photos.count ? String(format: "%02d ▸", i + 1) : "")
            .font(.custom("DINCondensed-Bold", size: 12))
            .foregroundStyle(Theme.stamp)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}
