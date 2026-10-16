import Supabase
import SwiftUI

@main
struct TwentyFourApp: App {
  @State private var model = AppModel()
  @Environment(\.scenePhase) private var scenePhase
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  var body: some Scene {
    WindowGroup {
      Group {
        if model.isLoading {
          ProgressView()
        } else if model.session == nil {
          SignInView()
        } else if model.profileLoadFailed && model.profile == nil {
          OfflineView(model: model)
        } else if model.profile == nil {
          NameView(model: model)
        } else {
          RollsListView(model: model)
        }
      }
      .task {
        await model.start()
      }
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active {
          Task { await UploadQueue.shared.processAll() }
        }
      }
      .onOpenURL {
        url in Task { await model.handleURL(url) }
      }
    }
  }
}
