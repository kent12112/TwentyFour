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
      VStack(spacing: 0) {
        HStack {
          HStack(spacing: 6){
            Text("TwentyFour")
              .font(.custom("ChalkboardSE-Bold", size: 26))
            Circle()
              .fill(Theme.accent)
              .frame(width: 8, height: 8)
          }
          Spacer()
          Menu {
             Button("Sign Out", role: .destructive) {
                Task {
                  try? await SupabaseClient.shared.auth.signOut()
                }
              } 
              } label: {
                Image(systemName: "person.crop.circle")
                  .font(.system(size: 26))
          }
        }
        .padding(.horizontal)
        .foregroundStyle(Theme.ink)
        Button {
          showingNewRoll = true
        } label: {
          NewRollCard()
        }
        .buttonStyle(.plain)
        .padding()
        VStack(alignment: .leading, spacing: 4) {
          Text("Your Rolls")
            .font(.system(size: 22, weight: .bold, design: .rounded))
          Text("Photos stay hidden until all 24 shots are taken.")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.6))
        }
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 10)
        if isLoading {
          ProgressView()
            .frame(maxHeight: .infinity)
        } else if rolls.isEmpty {
          VStack(spacing: 8) {
            Image(systemName: "camera")
              .font(.system(size: 36))
            Text("No rolls yet")
              .font(.system(size: 16, weight: .bold, design: .rounded))
            Text("Create one above, or open an invite link from a friend.")
              .font(.system(size: 13, design: .rounded))
              .foregroundStyle(Theme.ink.opacity(0.6))
          }
          .multilineTextAlignment(.center)
          .foregroundStyle(Theme.ink)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.horizontal, 32)
        } else{
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
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(Theme.paper)
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .refreshable { await loadRolls() }
        }
      }
      .background(Theme.paper)
      .toolbar(.hidden, for: .navigationBar)
      .task(id: model.rollsVersion) { await loadRolls() }
      .sheet(isPresented: $showingNewRoll, onDismiss: {
        Task{
          await loadRolls() 
        }
      }) {NewRollView()}
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
