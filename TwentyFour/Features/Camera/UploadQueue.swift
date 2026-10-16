import Foundation
import Observation
import Supabase

@MainActor
@Observable

final class UploadQueue {
  static let shared = UploadQueue()
  private(set) var items: [PendingUpload] = []

  private let folder: URL
  private var queueFile: URL { folder.appendingPathComponent("queue.json") }
  private var isProcessing = false

  private init() {
    folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("PendingUploads")
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    load()
  }

  private func load() {
    guard let data = try? Data(contentsOf: queueFile) else { return }
    items = (try? JSONDecoder().decode([PendingUpload].self, from: data)) ?? []
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(items) else { return }
    try? data.write(to: queueFile)
  }

  func add(frame: Frame, data: Data) throws {
    let fileName = "\(frame.id.uuidString).jpg"
    try data.write(to: folder.appendingPathComponent(fileName))
    let upload = PendingUpload(
      frameId: frame.id,
      rollId: frame.rollId,
      frameNumber: frame.frameNumber,
      storagePath: PendingUpload.path(rollId: frame.rollId, frameId: frame.id),
      localFileName: fileName
    )
    items.append(upload)
    save()
  }

  func processAll() async {
    guard !isProcessing else { return }
    isProcessing = true
    defer { isProcessing = false }

    for upload in items {
      do {
        let data = try Data(contentsOf: folder.appendingPathComponent(upload.localFileName))
        try await deliver(upload, data: data)
        remove(upload)
      } catch UploadError.rollClosed {
        // the roll developed or filled up without this photo; nothing left to upload into
        print("Frame \(upload.frameNumber) can't be uploaded anymore, dropping it")
        remove(upload)
      } catch {
        print("Upload of frame \(upload.frameNumber) failed, will retry:", error)
      }
    }
  }

  // upload the file and finalize its frame; if the server released the frame
  // (it was offline too long before marking it captured), claim a new one and retry
  private func deliver(_ upload: PendingUpload, data: Data) async throws {
    try await uploadFile(upload.storagePath, data: data)
    do {
      try await finalize(upload)
    } catch let error as PostgrestError where error.message == "Frame not found" {
      let replacement = try await reclaim(upload)
      try await uploadFile(replacement.storagePath, data: data)
      try await finalize(replacement)
      _ = try? await SupabaseClient.shared.storage.from("frames").remove(paths: [upload.storagePath])
    }
  }

  private func uploadFile(_ path: String, data: Data) async throws {
    do {
      try await SupabaseClient.shared.storage
        .from("frames")
        .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
    } catch let error as StorageError where error.statusCode == "409" {
      // already uploaded on an earlier try
    }
  }

  private func finalize(_ upload: PendingUpload) async throws {
    do {
      let _: Roll = try await SupabaseClient.shared
        .rpc(
          "finalize_frame",
          params: FinalizeParams(p_frame_id: upload.frameId, p_storage_path: upload.storagePath)
        )
        .execute()
        .value
    } catch let error as PostgrestError where error.message == "Frame is not reserved" {
      // already finalized on an earlier try
    }
  }

  // take a fresh frame number for a photo whose old frame was released
  private func reclaim(_ upload: PendingUpload) async throws -> PendingUpload {
    let frame: Frame
    do {
      frame = try await SupabaseClient.shared
        .rpc("claim_frame", params: ["p_roll_id": upload.rollId])
        .execute()
        .value
    } catch let error as PostgrestError where error.message == "Roll is full" {
      throw UploadError.rollClosed
    }
    var replacement = upload
    replacement.frameId = frame.id
    replacement.frameNumber = frame.frameNumber
    replacement.storagePath = PendingUpload.path(rollId: frame.rollId, frameId: frame.id)
    if let index = items.firstIndex(where: { $0.id == upload.id }) {
      items[index] = replacement
      save()
    }
    return replacement
  }

  private func remove(_ upload: PendingUpload) {
    try? FileManager.default.removeItem(at: folder.appendingPathComponent(upload.localFileName))
    items.removeAll { $0.id == upload.id }
    save()
  }
}

enum UploadError: Error {
  case rollClosed
}
