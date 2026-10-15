import SwiftUI

struct RecapCardView: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int
  var template: RecapTemplate = .filmStrip

  var body: some View {
    switch template {
    case .filmStrip:
      FilmStripCard(roll: roll, photos: photos, peopleCount: peopleCount)
    case .prints:
      PrintsCard(roll: roll, photos: photos, peopleCount: peopleCount)
    case .hero:
      HeroCard(roll: roll, photos: photos, peopleCount: peopleCount)
    }
  }
}

// "TwentyFour •" — same on every template
struct RecapWordmark: View {
  var body: some View {
    HStack(spacing: 6) {
      Text("TwentyFour")
        .font(.custom("ChalkboardSE-Bold", size: 22))
      Circle()
        .fill(Theme.accent)
        .frame(width: 7, height: 7)
    }
  }
}

// name, details, counts, tagline — same on every template
struct RecapFooter: View {
  let roll: Roll
  let peopleCount: Int
  let secondary: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(roll.name)
        .font(.custom("Futura-CondensedExtraBold", size: 40))
        .textCase(.uppercase)
      Text(roll.details)
        .font(.custom("DINCondensed-Bold", size: 16))
        .foregroundStyle(secondary)
      Text("\(roll.framesTaken) shots · \(peopleCount) friends")
        .font(.custom("DINCondensed-Bold", size: 16))
        .foregroundStyle(secondary)
      Text("shot together on TwentyFour")
        .font(.custom("Courier-Bold", size: 12))
        .foregroundStyle(Theme.stamp)
        .padding(.top, 8)
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
}
