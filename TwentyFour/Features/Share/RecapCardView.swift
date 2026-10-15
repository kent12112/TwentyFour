import SwiftUI

// The shareable recap, 360×640 points (1080×1920 when rendered at 3×).
struct RecapCardView: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int
  var template: RecapTemplate = .mosaic

  var body: some View {
    switch template {
    case .mosaic:
      MosaicCard(roll: roll, photos: photos, peopleCount: peopleCount)
    case .filmStrip:
      FilmStripCard(roll: roll, photos: photos, peopleCount: peopleCount)
    case .prints:
      PrintsCard(roll: roll, photos: photos, peopleCount: peopleCount)
    case .hero:
      HeroCard(roll: roll, photos: photos, peopleCount: peopleCount)
    }
  }
}

// Title, TF number, meta line and divider — the same on every template.
struct RecapHeader: View {
  let roll: Roll
  let peopleCount: Int
  var dark = false

  private var subtle: Color { dark ? Theme.paper.opacity(0.55) : Theme.muted }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        Text(roll.name)
          .font(Theme.sans(30))
          .textCase(.uppercase)
          .lineLimit(2)
          .minimumScaleFactor(0.7)
          .lineSpacing(-4)
        Spacer(minLength: 12)
        Text(roll.recapNumber)
          .metaStyle(7, color: subtle)
          .padding(.top, 4)
      }
      HStack {
        Text(roll.metaLine)
        Spacer()
        Text("\(roll.frameCount) frames · \(peopleCount) \(peopleCount == 1 ? "person" : "people")")
      }
      .metaStyle(7, color: subtle)
      Rectangle()
        .fill(dark ? Theme.paper.opacity(0.25) : Theme.ink)
        .frame(height: 1)
    }
  }
}

// TWENTYFOUR · ● ONE CAMERA · EVERYONE'S NIGHT — the same on every template.
struct RecapFooter: View {
  var dark = false

  var body: some View {
    HStack {
      Text("TwentyFour")
        .font(Theme.sans(10, .bold))
        .textCase(.uppercase)
        .tracking(0.5)
      Spacer()
      HStack(spacing: 5) {
        Circle()
          .fill(Theme.accent)
          .frame(width: 5, height: 5)
        Text("One camera · everyone's night")
          .metaStyle(6.5, color: dark ? Theme.paper.opacity(0.55) : Theme.muted)
      }
    }
  }
}

// a photo cropped to fill its box, with an optional small frame number
struct RecapPhoto: View {
  let image: UIImage?
  var number: Int? = nil

  var body: some View {
    Color.clear
      .overlay {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else {
          Theme.ink.opacity(0.06)
        }
      }
      .clipped()
      .overlay(alignment: .topLeading) {
        if let number {
          Text(String(format: "%02d", number))
            .font(Theme.mono(6))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 1)
            .padding(4)
        }
      }
  }
}

extension Roll {
  // the orange date stamp, like '26 10 14
  var stampText: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "''yy MM dd"
    return formatter.string(from: startsAt ?? createdAt)
  }

  // a small catalog number for the card, like TF-A8F
  var recapNumber: String {
    "TF-" + inviteCode.prefix(3).uppercased()
  }
}
