import SwiftUI

// The developed roll as a loose pile of prints, with dark contact strips mixed in.
// Row shapes, print sizes, tilts and offsets all vary, but they're derived from the
// roll id and frame numbers, so the same roll always looks the same (no jumping on redraw).
struct DevelopedGrid: View {
  let frames: [Frame]
  let photoURLs: [UUID: URL]
  let frameCount: Int
  let onTap: (Frame) -> Void

  private enum Shape: CaseIterable {
    case pair, single, stripRight, stripLeft, trio

    var size: Int {
      switch self {
      case .pair: 2
      case .single: 1
      case .stripRight, .stripLeft: 4
      case .trio: 3
      }
    }
  }

  private struct Row: Identifiable {
    let id: Int
    let shape: Shape
    let frames: [Frame]
  }

  // a stable number for this roll, so each roll gets its own arrangement
  private var seed: Int {
    guard let id = frames.first?.rollId else { return 0 }
    return Int(id.uuid.0) | Int(id.uuid.1) << 8 | Int(id.uuid.2) << 16
  }

  // stable "random" number 0..<1 from a frame/row number and a salt
  private func random(_ n: Int, _ salt: Int) -> Double {
    var x = UInt64(truncatingIfNeeded: n &* 2_654_435_761 &+ salt &* 40_503 &+ seed)
    x ^= x >> 13
    x = x &* 0x5bd1_e995
    x ^= x >> 15
    return Double(x % 10_000) / 10_000
  }

  private func random(_ n: Int, _ salt: Int, in range: ClosedRange<Double>) -> Double {
    range.lowerBound + random(n, salt) * (range.upperBound - range.lowerBound)
  }

  private var rows: [Row] {
    var result: [Row] = []
    var i = 0
    var last: Shape?
    var strips = 0
    while i < frames.count {
      let remaining = frames.count - i
      let lastWasStrip = last == .stripLeft || last == .stripRight
      // pick a shape that fits and isn't the same as the previous row;
      // at most 2 contact strips per roll, never two strip rows in a row;
      // pairs are listed twice so they come up more often
      let options = (Shape.allCases + [.pair]).filter { shape in
        let isStrip = shape == .stripLeft || shape == .stripRight
        return shape.size <= remaining && shape != last
          && !(isStrip && (lastWasStrip || strips >= 2))
      }
      let pick = options.isEmpty
        ? Shape.single
        : options[Int(random(result.count, 1) * Double(options.count)) % options.count]
      result.append(Row(id: result.count, shape: pick, frames: Array(frames[i..<i + pick.size])))
      i += pick.size
      last = pick
      if pick == .stripLeft || pick == .stripRight { strips += 1 }
    }
    return result
  }

  var body: some View {
    LazyVStack(spacing: -4) {
      ForEach(rows) { row in
        rowView(row)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 28)
  }

  @ViewBuilder
  private func rowView(_ row: Row) -> some View {
    let f = row.frames
    switch row.shape {
    case .pair:
      HStack(alignment: .top, spacing: -10) {
        print(f[0], width: random(f[0].frameNumber, 2, in: 160...185))
        print(f[1], width: random(f[1].frameNumber, 2, in: 150...180))
          .offset(y: random(f[1].frameNumber, 3, in: 8...44))
      }
    case .single:
      print(f[0], width: random(f[0].frameNumber, 2, in: 220...260))
        .offset(x: random(f[0].frameNumber, 4, in: -50...50))
    case .stripRight:
      HStack(alignment: .top, spacing: 0) {
        print(f[0], width: random(f[0].frameNumber, 2, in: 190...215))
        contactStrip(Array(f[1...]))
          .offset(y: random(f[1].frameNumber, 3, in: 0...30))
          .zIndex(1)
      }
    case .stripLeft:
      HStack(alignment: .top, spacing: 0) {
        contactStrip(Array(f[0..<3]))
          .offset(y: random(f[0].frameNumber, 3, in: 10...36))
          .zIndex(1)
        print(f[3], width: random(f[3].frameNumber, 2, in: 190...215))
      }
    case .trio:
      HStack(alignment: .top, spacing: -8) {
        ForEach(Array(f.enumerated()), id: \.element.id) { j, frame in
          print(frame, width: random(frame.frameNumber, 2, in: 118...130))
            .offset(y: j == 1 ? random(frame.frameNumber, 3, in: 18...40) : random(frame.frameNumber, 3, in: 0...12))
        }
      }
    }
  }

  // shape to show while a photo is still loading
  private func ratio(_ frame: Frame) -> CGFloat {
    let ratios: [CGFloat] = [0.8, 1.0, 1.3, 0.85, 1.25]
    return ratios[Int(random(frame.frameNumber, 5) * Double(ratios.count)) % ratios.count]
  }

  private func photo(_ frame: Frame, ratio: CGFloat) -> some View {
    Color.clear
      .aspectRatio(ratio, contentMode: .fit)
      .overlay {
        AsyncImage(url: photoURLs[frame.id]) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Theme.ink.opacity(0.08)
        }
      }
      .clipped()
  }

  // a white-bordered print with "01 / 24" in the bottom border
  private func print(_ frame: Frame, width: Double) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      // the print takes the photo's real shape: wide for landscape, tall for portrait
      PrintPhoto(url: photoURLs[frame.id], placeholderRatio: ratio(frame))
      Text(String(format: "%02d / %d", frame.frameNumber, frameCount))
        .font(Theme.mono(8))
        .foregroundStyle(Theme.muted)
    }
    .padding(7)
    .padding(.bottom, 4)
    .background(.white)
    .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
    .frame(width: width)
    .rotationEffect(.degrees(random(frame.frameNumber, 6, in: -4...4)))
    .contentShape(Rectangle())
    .onTapGesture { onTap(frame) }
  }

  // a vertical strip of small frames on dark film
  private func contactStrip(_ strip: [Frame]) -> some View {
    VStack(spacing: 6) {
      ForEach(strip) { frame in
        VStack(alignment: .leading, spacing: 3) {
          photo(frame, ratio: 4 / 3)
          Text(String(format: "%02d", frame.frameNumber))
            .font(Theme.mono(7))
            .foregroundStyle(Theme.stamp)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap(frame) }
      }
    }
    .padding(6)
    .background(Theme.film)
    .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
    .frame(width: 92)
    .rotationEffect(.degrees(random(strip[0].frameNumber, 7, in: -2.5...2.5)))
  }
}

// Loads a photo and shows it at its own aspect ratio (no cropping).
private struct PrintPhoto: View {
  let url: URL?
  let placeholderRatio: CGFloat
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(image.size.width / max(image.size.height, 1), contentMode: .fit)
      } else {
        Theme.ink.opacity(0.08)
          .aspectRatio(placeholderRatio, contentMode: .fit)
      }
    }
    .task(id: url) {
      guard let url, image == nil else { return }
      if let (data, _) = try? await URLSession.shared.data(from: url) {
        image = UIImage(data: data)
      }
    }
  }
}
