import Supabase
import SwiftUI

struct RollsListView: View {
  @State private var rolls: [Roll] = []
  @State private var showingNewRoll = false
  var body: some View {
    NavigationStack {
      List(rolls) { roll in
        HStack {
          Text(roll.name)
          Spacer()
          Text(String(roll.framesTaken) + "/" + String(roll.frameCount))
        }
      }
      .task { await loadRolls() }
      .navigationTitle("Your Rolls")
      .toolbar {
        Button("Sign Out") {
          Task {
            try? await SupabaseClient.shared.auth.signOut()
          }
        }
        Button {
          showingNewRoll = true
        } label: {
          Image(systemName: "plus")
        }
      }
      .sheet(isPresented: $showingNewRoll, onDismiss: {
        Task {
          await loadRolls() 
        }
      }) {NewRollView()}
    }
  }
  private func loadRolls() async {
    do {
      rolls = try await SupabaseClient.shared
        .from("rolls")
        .select()
        .order("created_at", ascending: false)
        .execute()
        .value
    } catch {
      print("Failed to load rolls:", error)
    }
  }
}
