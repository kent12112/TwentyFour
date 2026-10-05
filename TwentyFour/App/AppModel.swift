import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class AppModel {
  var session: Session?
  var isLoading = true
  var profile: Profile?
  var rollsVersion = 0

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
  func handleURL(_ url: URL) async {
    guard url.scheme == "twentyfour", url.host == "join" else {return}
    guard let rollId = UUID(uuidString: url.lastPathComponent) else {return}
    guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first(where: {$0.name == "code"})?
      .value else {return}

    do {
      let roll: Roll = try await SupabaseClient.shared
        .rpc("join_roll", params: JoinRollParams(p_roll_id: rollId, p_invite_code: code))
        .execute()
        .value
      print("Joined", roll.name)
      rollsVersion += 1
    } catch {
      print("Failed to join roll:", error)
    }
  }
}

struct JoinRollParams: Encodable {
  let p_roll_id: UUID
  let p_invite_code: String
}