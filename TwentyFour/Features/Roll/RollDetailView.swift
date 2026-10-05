import SwiftUI

struct RollDetailView: View {
  @State private var showingInvite = false
  let roll: Roll
  var body: some View {
    VStack(spacing: 16) {
      Text(String(roll.framesTaken) + "/" + String(roll.frameCount))
      Button("Invite") {
        showingInvite = true
      }
    }
    .navigationTitle(roll.name)
    .sheet(isPresented: $showingInvite){
        InviteView(roll: roll)
      }
  }
}