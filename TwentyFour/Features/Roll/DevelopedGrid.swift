import SwiftUI

// The developed roll as a mosaic: rows of photos in mixed sizes with thin gaps,
// like the Mosaic recap card. Row layouts vary, but they're derived from the roll id,
// so the same roll always looks the same.
struct DevelopedGrid: View {
  let frames: [Frame]
  let photoURLs: [UUID: URL]
  let frameCount: Int
  let width: CGFloat
  let onTap: (Frame) -> Void

  private let gap: CGFloat = 6

  private enum Layout: CaseIterable {
    case wideNarrow  // ▇▇▇▇ ▇▇
    case narrowWide  // ▇▇ ▇▇▇▇
    case three  // ▇▇ ▇▇ ▇▇
    case bigLeft  // big photo + two stacked on the right
    case bigRight  // two stacked on the left + big photo
    case even  // ▇▇▇ ▇▇▇

    var size: Int {
      switch self {
      case .wideNarrow, .narrowWide, .even: 2
      case .three, .bigLeft, .bigRight: 3
      }
    }
  }

  private struct Row: Identifiable {
    let id: Int
    let layout: Layout
    let frames: [Frame]
  }

  // a stable number for this roll, so each roll gets its own arrangement
  private var seed: Int {
    guard let id = frames.first?.rollId else { return 0 }
    return Int(id.uuid.0) | Int(id.uuid.1) << 8 | Int(id.uuid.2) << 16
  }

  // stable "random" number 0..<1
  private func random(_ n: Int) -> Double {
    var x = UInt64(truncatingIfNeeded: n &* 2_654_435_761 &+ seed)
    x ^= x >> 13
    x = x &* 0x5bd1_e995
    x ^= x >> 15
    return Double(x % 10_000) / 10_000
  }

  private var rows: [Row] {
    var result: [Row] = []
    var i = 0
    var last: Layout?
    while i < frames.count {
      let remaining = frames.count - i
      let options = Layout.allCases.filter { $0.size <= remaining && $0 != last }
      let pick =
        options.isEmpty
        ? Layout.even
        : options[Int(random(result.count) * Double(options.count)) % options.count]
      let count = min(pick.size, remaining)
      result.append(Row(id: result.count, layout: pick, frames: Array(frames[i..<i + count])))
      i += count
      last = pick
    }
    return result
  }

  var body: some View {
    LazyVStack(spacing: gap) {
      ForEach(rows) { row in
        rowView(row)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 24)
  }

  // width of a cell that takes `fraction` of a row with `count` cells (gaps taken out first)
  private func w(_ fraction: CGFloat, of count: Int) -> CGFloat {
    (width - gap * CGFloat(count - 1)) * fraction
  }

  @ViewBuilder
  private func rowView(_ row: Row) -> some View {
    let f = row.frames
    switch row.layout {
    case .wideNarrow:
      HStack(spacing: gap) {
        cell(f[0]).frame(width: w(0.64, of: 2), height: width * 0.44)
        if f.count > 1 { cell(f[1]).frame(width: w(0.36, of: 2), height: width * 0.44) }
      }
    case .narrowWide:
      HStack(spacing: gap) {
        cell(f[0]).frame(width: w(0.4, of: 2), height: width * 0.52)
        if f.count > 1 { cell(f[1]).frame(width: w(0.6, of: 2), height: width * 0.52) }
      }
    case .even:
      HStack(spacing: gap) {
        ForEach(f) { frame in
          cell(frame).frame(width: w(0.5, of: 2), height: width * 0.6)
        }
        if f.count == 1 { Color.clear.frame(width: w(0.5, of: 2), height: 1) }
      }
    case .three:
      HStack(spacing: gap) {
        ForEach(f) { frame in
          cell(frame).frame(width: w(1 / 3, of: 3), height: width * 0.42)
        }
      }
    case .bigLeft:
      let big = width * 0.7
      HStack(spacing: gap) {
        cell(f[0]).frame(width: w(0.64, of: 2), height: big)
        VStack(spacing: gap) {
          cell(f[1]).frame(width: w(0.36, of: 2), height: (big - gap) / 2)
          cell(f[2]).frame(width: w(0.36, of: 2), height: (big - gap) / 2)
        }
      }
    case .bigRight:
      let big = width * 0.7
      HStack(spacing: gap) {
        VStack(spacing: gap) {
          cell(f[0]).frame(width: w(0.36, of: 2), height: (big - gap) / 2)
          cell(f[1]).frame(width: w(0.36, of: 2), height: (big - gap) / 2)
        }
        cell(f[2]).frame(width: w(0.64, of: 2), height: big)
      }
    }
  }

  // one photo filling its box, with the frame number in the corner
  private func cell(_ frame: Frame) -> some View {
    CachedPhoto(url: photoURLs[frame.id])
      .overlay(alignment: .topLeading) {
        Text(String(format: "%02d", frame.frameNumber))
          .font(Theme.mono(8))
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.6), radius: 1)
          .padding(6)
      }
      .contentShape(Rectangle())
      .onTapGesture { onTap(frame) }
  }
}

// Downloaded photos, kept for the session so scrolling back doesn't re-download.
@MainActor
enum PhotoCache {
  static var images: [URL: UIImage] = [:]
}

// Loads a photo (or takes it from the cache) and fills its box, cropping the edges.
private struct CachedPhoto: View {
  let url: URL?
  @State private var image: UIImage?

  init(url: URL?) {
    self.url = url
    _image = State(initialValue: url.flatMap { PhotoCache.images[$0] })
  }

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
      .task(id: url) {
        guard let url, image == nil else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
          let loaded = UIImage(data: data)
        {
          PhotoCache.images[url] = loaded
          image = loaded
        }
      }
  }
}
