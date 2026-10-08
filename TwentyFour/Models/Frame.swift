import Foundation

struct Frame: Codable, Identifiable {
  let id: UUID
  let rollId: UUID
  let frameNumber: Int
  let photographerId: UUID?
  let takenAt: Date
  let storagePath: String?
  let status: String

  enum CodingKeys: String, CodingKey {
    case id
    case rollId = "roll_id"
    case frameNumber = "frame_number"
    case photographerId = "photographer_id"
    case takenAt = "taken_at"
    case storagePath = "storage_path"
    case status
  }
}