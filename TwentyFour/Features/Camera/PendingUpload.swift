import Foundation

struct PendingUpload: Codable, Identifiable {
  // var, because a photo whose frame was released gets a new frame (see UploadQueue)
  var frameId: UUID
  let rollId: UUID
  var frameNumber: Int
  var storagePath: String
  let localFileName: String
  var id: String { localFileName }

  // <roll id>/<frame id>.jpg — unique per frame, so a reused frame number never
  // collides with another photo's file
  static func path(rollId: UUID, frameId: UUID) -> String {
    "\(rollId.uuidString.lowercased())/\(frameId.uuidString.lowercased()).jpg"
  }
}
