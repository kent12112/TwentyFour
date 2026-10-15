import AuthenticationServices
import Supabase
import SwiftUI

struct SignInView: View {
  var body: some View {
    ZStack {
      Theme.paper.ignoresSafeArea()
      VStack(spacing: 16) {
        Spacer()
        Image("hero")
          .resizable()
          .scaledToFill()
          .frame(width: 240, height: 170)
          .clipped()
          .overlay(alignment: .bottomTrailing) {
            Text("'26 10 14")
              .font(.system(size: 13, weight: .semibold, design: .monospaced))
              .foregroundStyle(Theme.stamp)
              .padding(8)
          }
          .padding(8)
          .background(.white)
          .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
          .rotationEffect(.degrees(-3))
          .padding(.bottom, 24)
        HStack(spacing: 8) {
          Text("TwentyFour")
            .font(.custom("ChalkboardSE-Bold", size: 40))
          Circle()
            .fill(Theme.accent)
            .frame(width: 12, height: 12)
        }
        Text("The group disposable camera")
          .font(.system(size: 15, design: .monospaced))

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
