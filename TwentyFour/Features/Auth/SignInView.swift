import SwiftUI
import AuthenticationServices
import Supabase

struct SignInView: View {
  var body: some View {
    ZStack {
      Theme.paper.ignoresSafeArea()
      VStack(spacing: 16){
        Spacer()
        HStack(spacing: 8) {
          Text("TWENTYFOUR")
            .font(.system(size: 40, weight: .black))
          Circle()
            .fill(Theme.accent)
            .frame(width: 12, height: 12)
        }
        Text("The group disposable camera.")
          .font(.system(size: 15, design: .monospaced))

        Spacer()
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
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        Text("24 shots · no retakes · develops when the roll is full")
          .font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.secondary)
      }
       .padding(24)
       .foregroundStyle(Theme.ink)
    }
  }
}