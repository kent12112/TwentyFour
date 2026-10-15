import Foundation

struct Member: Codable { let profile: Profile }

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
  let members: [Member]?

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
    case members
  }
}
extension Roll {
  // "Oct 01 · NYC" (shown uppercase with .metaStyle)
  var metaLine: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM dd"
    let date = formatter.string(from: startsAt ?? createdAt)
    if let location, !location.isEmpty {
      return "\(date) · \(location)"
    }
    return date
  }

  var isDeveloped: Bool { status == "developed" }

  var details: String {
    let date = (startsAt ?? createdAt).formatted(date: .abbreviated, time: .omitted)
    if let location = location, !location.isEmpty {
      return "\(date) · \(location)"
    }
    return date
  }
}
