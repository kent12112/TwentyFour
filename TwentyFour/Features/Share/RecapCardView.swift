import SwiftUI

struct RecapCardView: View {
  let roll: Roll
  let photos: [UIImage]
  let peopleCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(roll.name.uppercased()).font(.system(size: 32, weight: .black))

      Text((roll.startsAt ?? roll.createdAt).formatted(date: .abbreviated, time: .omitted))
        .font(.system(size: 13, design: .monospaced))

      Text("\(roll.frameCount) frames · \(peopleCount) people")
        .font(.system(size: 13, design: .monospaced))

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
        ForEach(photos.indices, id: \.self) {
          i in Image(uiImage: photos[i])
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 120)
            .clipped()
        }
      }

      Spacer()

      HStack(spacing: 6) {
        Text("TWENTYFOUR")
          .font(.system(size: 16, weight: .bold))
        Circle()
          .fill(Theme.accent)
          .frame(width: 8, height: 8)
      }
      Text("ONE CAMERA · EVERYONE'S NIGHT")
        .font(.system(size: 10, design: .monospaced))
    }
    .padding(24)
    .frame(width: 360, height: 640)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }
}

