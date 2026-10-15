import SwiftUI

enum Theme {
  // colors
  static let paper = Color(red: 0xF2 / 255, green: 0xF0 / 255, blue: 0xEB / 255)
  static let ink = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
  static let accent = Color(red: 0xE5 / 255, green: 0x48 / 255, blue: 0x4D / 255)
  static let stamp = Color(red: 1, green: 0.55, blue: 0.15)
  static let film = Color(red: 0.11, green: 0.10, blue: 0.09)
  static let muted = ink.opacity(0.5)
  static let line = ink.opacity(0.12)

  // avatar colors, picked per person from their id
  static let avatarColors: [Color] = [
    Color(red: 0.85, green: 0.55, blue: 0.48),
    Color(red: 0.45, green: 0.56, blue: 0.47),
    Color(red: 0.42, green: 0.50, blue: 0.68),
    Color(red: 0.55, green: 0.53, blue: 0.50),
    Color(red: 0.78, green: 0.64, blue: 0.40),
  ]

  // fonts
  enum Weight { case regular, medium, semibold, bold }

  // Inter: titles, names, buttons
  static func sans(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
    switch weight {
    case .regular: .custom("Inter-Regular", size: size)
    case .medium: .custom("Inter-Medium", size: size)
    case .semibold: .custom("Inter-SemiBold", size: size)
    case .bold: .custom("Inter-Bold", size: size)
    }
  }

  // JetBrains Mono: dates, counts, labels
  static func mono(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
    switch weight {
    case .regular: .custom("JetBrainsMono-Regular", size: size)
    case .medium, .semibold: .custom("JetBrainsMono-Medium", size: size)
    case .bold: .custom("JetBrainsMono-Bold", size: size)
    }
  }
}

extension View {
  // small uppercase mono label, like "OCT 01 · NYC" or "24 FRAMES · 7 PEOPLE"
  func metaStyle(_ size: CGFloat = 10, color: Color = Theme.muted) -> some View {
    self
      .font(Theme.mono(size))
      .textCase(.uppercase)
      .tracking(0.8)
      .foregroundStyle(color)
  }
}
