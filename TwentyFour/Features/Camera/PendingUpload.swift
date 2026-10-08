import Foundation

struct PendingUpload: Codable, Identifiable {
  let frameId: UUID
  let rollId: UUID
  let frameNumber: Int
  let storagePath: String
  let localFileName: String
  var id: UUID {frameId}
}