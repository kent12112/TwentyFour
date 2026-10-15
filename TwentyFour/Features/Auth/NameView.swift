import SwiftUI

struct NameView: View {
  let model: AppModel
  @State private var name = ""

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespaces)
  }

  var body: some View {
    ZStack{
      Theme.paper.ignoresSafeArea()
      VStack(alignment: .leading, spacing: 16) {
        Spacer()
        VStack(alignment: .leading, spacing: 4) {
          Text("What's your name?")
            .font(.system(size: 28, weight: .bold, design: .rounded))
          Text("This is how friends will see you on a roll.")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.6))

        }
        TextField("Your name", text: $name)
          .font(.system(size: 17, design: .rounded))
          .textContentType(.givenName)
          .padding()
          .background(.white, in: RoundedRectangle(cornerRadius: 12))
        Spacer()
        Button {
            Task {
              await model.createProfile(displayName: trimmedName)
            }
        } label: {
              Text("Continue")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.4 : 1)
      }
      .padding(24)
      .foregroundStyle(Theme.ink)
    }
  }
}