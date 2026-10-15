import Supabase
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ applicaton: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    print("Push token:", token)
    Task {
      do {
        let userId = try await SupabaseClient.shared.auth.session.user.id
        try await SupabaseClient.shared
          .from("push_tokens")
          .upsert(PushTokenRow(user_id: userId, token: token))
          .execute()
        print("Push token saved")
      } catch {
        print("Saving push token failed:", error)
      }
    }
  }

  func application(
    _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Push registration failed:", error)
  }
}

struct PushTokenRow: Encodable {
  let user_id: UUID
  let token: String
}
