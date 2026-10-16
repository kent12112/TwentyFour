import Supabase
import SwiftUI

// Shown when the profile couldn't be loaded (usually no connection),
// instead of wrongly asking an existing user for their name again.
struct OfflineView: View {
  let model: AppModel
  @State private var isRetrying = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("TwentyFour")
        .font(Theme.sans(17, .bold))
        .textCase(.uppercase)
        .tracking(0.5)
        .padding(.top, 20)

      Spacer()

      VStack(alignment: .leading, spacing: 10) {
        Image(systemName: "wifi.slash")
          .font(.system(size: 26, weight: .light))
          .padding(.bottom, 8)
        Text("Can't connect")
          .font(Theme.sans(30))
        Text("Check your connection and try again. Your rolls and photos are safe.")
          .font(Theme.sans(14))
          .foregroundStyle(Theme.muted)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()

      Button {
        isRetrying = true
        Task {
          await model.retryLoadProfile()
          isRetrying = false
        }
      } label: {
        Group {
          if isRetrying {
            ProgressView().tint(.white)
          } else {
            Text("Try again")
          }
        }
        .font(Theme.sans(15, .medium))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Theme.ink)
      }
      .buttonStyle(.plain)
      .disabled(isRetrying)

      Button("Sign out") {
        Task { try? await SupabaseClient.shared.auth.signOut() }
      }
      .font(Theme.sans(13))
      .foregroundStyle(Theme.muted)
      .frame(maxWidth: .infinity)
      .padding(.top, 16)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }
}
