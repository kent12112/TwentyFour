import Supabase
import SwiftUI
import UserNotifications

struct RollsListView: View {
  @State private var rolls: [Roll] = []
  @State private var showingNewRoll = false
  @State private var isLoading = true
  let model: AppModel
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        // header: TWENTYFOUR · settings
        HStack {
          Text("TwentyFour")
            .font(Theme.sans(17, .bold))
            .textCase(.uppercase)
            .tracking(0.5)
          Spacer()
          Menu {
            Button("Sign Out", role: .destructive) {
              Task {
                try? await SupabaseClient.shared.auth.signOut()
              }
            }
          } label: {
            Image(systemName: "gearshape")
              .font(.system(size: 17, weight: .light))
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
        }
        .padding(.leading, 24)
        .padding(.trailing, 12)
        .padding(.top, 8)

        // title
        VStack(alignment: .leading, spacing: 10) {
          Text("Your Rolls")
            .font(Theme.sans(30))
          Text("One camera, passed around. Everyone gets the photos when the roll is done.")
            .font(Theme.sans(13))
            .foregroundStyle(Theme.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)

        Button {
          showingNewRoll = true
        } label: {
          NewRollCard()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)

        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if rolls.isEmpty {
          VStack(spacing: 8) {
            Text("No rolls yet")
              .font(Theme.sans(15, .medium))
            Text("Create one above, or open an invite link from a friend.")
              .font(Theme.sans(13))
              .foregroundStyle(Theme.muted)
          }
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.horizontal, 32)
        } else {
          List(rolls) { roll in
            ZStack {
              RollRow(roll: roll)
              NavigationLink {
                RollDetailView(roll: roll)
              } label: {
                EmptyView()
              }
              .opacity(0)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
            .listRowBackground(Theme.paper)
            .listRowSeparatorTint(Theme.line)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
            .alignmentGuide(.listRowSeparatorTrailing) { d in d.width }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .refreshable { await loadRolls() }
        }
      }
      .foregroundStyle(Theme.ink)
      .background(Theme.paper)
      .toolbar(.hidden, for: .navigationBar)
      .task(id: model.rollsVersion) { await loadRolls() }
      .sheet(
        isPresented: $showingNewRoll,
        onDismiss: {
          Task {
            await loadRolls()
          }
        }
      ) { NewRollView() }
      .task {
        do {
          let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
          if granted {
            UIApplication.shared.registerForRemoteNotifications()
          }
        } catch {
          print("Notification permission error:", error)
        }
      }
    }
    .tint(Theme.ink)
  }
  private func loadRolls() async {
    do {
      rolls = try await SupabaseClient.shared
        .from("rolls")
        .select("*, members:roll_members(profile:profiles(id, display_name, color))")
        .order("created_at", ascending: false)
        .execute()
        .value
    } catch {
      print("Failed to load rolls:", error)
    }
    isLoading = false
  }
}
