import SwiftUI

struct RollDetailView: View {
  @State private var showingInvite = false
  @State private var showingCamera = false
  let roll: Roll
  var body: some View {
    VStack(spacing: 16) {
      Text(String(roll.framesTaken) + "/" + String(roll.frameCount))
      Button("Shoot") {
        showingCamera = true
      }
      Button("Invite") {
        showingInvite = true
      }
    }
    .navigationTitle(roll.name)
    .sheet(isPresented: $showingInvite){
        InviteView(roll: roll)
      }
    .fullScreenCover(isPresented: $showingCamera) {
      CameraView(roll: roll)
    }
  }
}