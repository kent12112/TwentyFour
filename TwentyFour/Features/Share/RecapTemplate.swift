import Foundation

enum RecapTemplate: String, CaseIterable, Identifiable {
  case mosaic, filmStrip, prints, hero

  var id: Self { self }

  var title: String {
    switch self {
    case .mosaic: "Mosaic"
    case .filmStrip: "Film"
    case .prints: "Prints"
    case .hero: "Hero"
    }
  }

  var maxPhotos: Int {
    switch self {
    case .mosaic: 6
    case .filmStrip: 12
    case .prints: 5
    case .hero: 1
    }
  }
}
