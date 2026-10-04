import SwiftUI

struct NameView: View {
  let model: AppModel
  @State private var name = ""

  var body: some View {
    VStack(spacing: 16) {
      Text("What's your name?")
      TextField("Your name", text: $name)
      Button("Continue")
        {
          Task {
            await model.createProfile(displayName: name)
          }
        }.disabled(name.isEmpty)
    }
    .padding()
  }
}