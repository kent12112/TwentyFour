import Foundation

struct Roll: Codable, Identifiable {
  let id: UUID
  let name: String
  let eventType: String?
  let startsAt: Date?
  let location: String?
  let createdBy: UUID?
  let frameCount: Int
  let framesTaken: Int
  let status: String
  let developedAt: Date?
  let createdAt: Date
  let inviteCode: String

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case eventType = "event_type"
    case startsAt = "starts_at"
    case location
    case createdBy = "created_by"
    case frameCount = "frame_count"
    case framesTaken = "frames_taken"
    case status
    case developedAt = "developed_at"
    case createdAt = "created_at"
    case inviteCode = "invite_code"
  }
}