import Foundation
import Observation
import Supabase

@MainActor
@Observable

final class UploadQueue {
  static let shared = UploadQueue()
  private(set) var items: [PendingUpload] = []

  private let folder: URL
  private var queueFile: URL { folder.appendingPathComponent("queue.json")}
  private var isProcessing = false

  private init() {
    folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("PendingUploads")
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    load()
  }

  private func load() {
    guard let data = try? Data(contentsOf: queueFile ) else { return }
    items = (try? JSONDecoder().decode([PendingUpload].self, from: data)) ?? []
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(items) else {return}
    try? data.write(to: queueFile)
  }

  func add(frame: Frame, storagePath: String, data: Data) throws {
    let fileName = "\(frame.id.uuidString).jpg"
    try data.write(to: folder.appendingPathComponent(fileName))
    let upload = PendingUpload(
      frameId: frame.id,
      rollId: frame.rollId,
      frameNumber: frame.frameNumber,
      storagePath: storagePath,
      localFileName: fileName
    )
    items.append(upload)
    save()
  }

  func processAll() async {
    guard !isProcessing else {return}
    isProcessing = true
    defer { isProcessing = false }
    
    for upload in items {
      do {
        let data = try Data(contentsOf: folder.appendingPathComponent(upload.localFileName))
        do {
          try await SupabaseClient.shared.storage
            .from("frames")
            .upload(upload.storagePath, data: data, options: FileOptions(contentType: "image/jpeg"))
          } catch let error as StorageError where error.statusCode == "409" {}
        let _: Roll = try await SupabaseClient.shared
          .rpc("finalize_frame", params: FinalizeParams(p_frame_id: upload.frameId, p_storage_path: upload.storagePath))
          .execute()
          .value
        
        remove(upload)
      } catch {
        print("Upload of frame \(upload.frameNumber) failed, will retry:", error)
      }
    }
  }
  
  private func remove(_ upload: PendingUpload) {
    try? FileManager.default.removeItem(at: folder.appendingPathComponent(upload.localFileName))
    items.removeAll { $0.frameId == upload.frameId }
    save()
  }
}