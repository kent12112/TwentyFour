import SwiftUI
import AuthenticationServices
import Supabase

struct SignInView: View {
  var body: some View {
    SignInWithAppleButton(.signIn) {
      request in request.requestedScopes = [.fullName]
    } onCompletion: { result in
      switch result {
        case .success(let authorization):
          guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Invalid state: A non-Apple ID credential was received.")
            return
          }
          guard 
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
          else {
            print("No identity Token")
            return
          }
          Task {
            do {
              let session = try await SupabaseClient.shared.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
                )
                print("Signed in as", session.user.id)
          } catch {
            print("Supabase sign-in failed:", error)
          }
          } 
        case .failure(let error):
          print("Apple sign-in failed:", error)
      }
    }
  }
}