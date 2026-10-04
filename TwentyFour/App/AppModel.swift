import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class AppModel {
  var session: Session?
  var isLoading = true
  var profile: Profile?

  func start() async {
    for await (_, session) in SupabaseClient.shared.auth.authStateChanges {
      if let session, session.isExpired {
        self.session = nil
      } else {
        self.session = session
      }

      if let session = self.session {
        await loadProfile(userId: session.user.id)
      } else {
        profile = nil
      }
      isLoading = false
    }
  }

  func loadProfile(userId: UUID) async {
    do {
      let profiles: [Profile] = try await SupabaseClient.shared
        .from("profiles")
        .select()
        .eq("id", value: userId)
        .execute()
        .value
      profile = profiles.first
    } catch {
      print("Failed to load profile:", error)
      profile = nil
    }
  }

  func createProfile(displayName: String) async {
    //session is optional because it needs to work when user is signed out
    guard let userId = session?.user.id else {return }

    let newProfile = Profile(id: userId, displayName: displayName, color: "#E5484D")

    do {
      try await SupabaseClient.shared
        .from("profiles")
        .insert(newProfile)
        .execute()
      profile = newProfile
    } catch {
      print("Failed to create profile:", error)
    }
  }
}