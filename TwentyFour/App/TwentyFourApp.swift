import SwiftUI
import Supabase

@main
struct TwentyFourApp: App {
  @State private var model = AppModel()

  var body: some Scene {
    WindowGroup {
      Group  {
        if model.isLoading {
          ProgressView()
        } else if model.session == nil {
          SignInView()
        } else if model.profile == nil {
          NameView(model: model)
        }else {
          Button("Sign Out") {
            Task {
              try? await SupabaseClient.shared.auth.signOut()
            }
          }
        }
      }
      .task {
        await model.start()
      }
    }
  }
}