import AuthenticationServices
import Supabase
import SwiftUI

struct SignInView: View {
  var body: some View {
    ZStack {
      Theme.paper.ignoresSafeArea()
      VStack(alignment: .leading, spacing: 0) {
        Text("TwentyFour")
          .font(Theme.sans(17, .bold))
          .textCase(.uppercase)
          .tracking(0.5)
          .padding(.top, 20)

        Spacer()

        Image("hero")
          .resizable()
          .scaledToFill()
          .frame(width: 250, height: 180)
          .clipped()
          .overlay(alignment: .bottomTrailing) {
            Text("'26 10 14")
              .font(Theme.mono(11, .medium))
              .foregroundStyle(Theme.stamp)
              .padding(8)
          }
          .padding(8)
          .padding(.bottom, 16)
          .background(.white)
          .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
          .rotationEffect(.degrees(-3))
          .frame(maxWidth: .infinity)

        VStack(alignment: .leading, spacing: 12) {
          Text("One camera.\nEveryone's night.")
            .font(Theme.sans(32))
          Text("The group disposable camera")
            .metaStyle(10)
        }
        .padding(.top, 48)

        Spacer()

        SignInWithAppleButton(.signIn) {
          request in
          request.requestedScopes = [.fullName]
        } onCompletion: { result in
          switch result {
          case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else {
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
        .frame(height: 52)
        Text("24 shots · no retakes · develops when the roll is full")
          .metaStyle(8)
          .frame(maxWidth: .infinity)
          .padding(.top, 14)
      }
      .padding(24)
      .foregroundStyle(Theme.ink)
    }
  }
}
