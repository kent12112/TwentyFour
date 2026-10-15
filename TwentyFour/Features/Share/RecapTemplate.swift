import Foundation

enum RecapTemplate: String, CaseIterable, Identifiable {
  case filmStrip, prints, hero

  var id: Self { self }

  var title: String {
    switch self {
    case .filmStrip: "Film"
    case .prints: "Prints"
    case .hero: "Hero"
    }
  }

  var maxPhotos: Int {
    switch self {
    case .filmStrip: 9
    case .prints: 5
    case .hero: 1
    }
  }
}
