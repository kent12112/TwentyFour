import Foundation


struct Profile: Codable {
  let id: UUID
  let displayName: String
  let color: String

  enum CodingKeys: String, CodingKey {
    case id
    case displayName = "display_name"
    case color
  }
}