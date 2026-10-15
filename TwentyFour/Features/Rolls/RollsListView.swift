import Supabase
import SwiftUI
import UserNotifications

struct RollsListView: View {
  @State private var rolls: [Roll] = []
  @State private var showingNewRoll = false
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
      }
      .background(Theme.paper)
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
  }
}
