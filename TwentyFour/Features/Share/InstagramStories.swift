import UIKit

// Opens Instagram's story editor with an image as the full-screen background.
// Needs FacebookAppID (a Meta App ID) in Info.plist and "instagram-stories" in LSApplicationQueriesSchemes.
enum InstagramStories {
  enum Problem {
    case notInstalled, missingAppID
  }

  private static var appID: String? {
    guard let id = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
      !id.isEmpty
    else { return nil }
    return id
  }

  @MainActor
  static func share(_ image: UIImage) -> Problem? {
    guard let check = URL(string: "instagram-stories://share"),
      UIApplication.shared.canOpenURL(check)
    else { return .notInstalled }
    guard let appID,
      let url = URL(string: "instagram-stories://share?source_application=\(appID)"),
      let data = image.pngData()
    else { return .missingAppID }

    UIPasteboard.general.setItems(
      [["com.instagram.sharedSticker.backgroundImage": data]],
      options: [.expirationDate: Date().addingTimeInterval(5 * 60)]
    )
    UIApplication.shared.open(url)
    return nil
  }
}
