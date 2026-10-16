import SwiftUI

struct NameView: View {
  let model: AppModel
  @State private var name = ""
  @State private var isSaving = false
  @State private var saveFailed = false

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespaces)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("TwentyFour")
        .font(Theme.sans(17, .bold))
        .textCase(.uppercase)
        .tracking(0.5)
        .padding(.top, 20)

      Spacer()

      VStack(alignment: .leading, spacing: 10) {
        Text("What's your name?")
          .font(Theme.sans(30))
        Text("This is how friends will see you on a roll.")
          .font(Theme.sans(14))
          .foregroundStyle(Theme.muted)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Name")
          .metaStyle(9)
        TextField("Your name", text: $name)
          .font(Theme.sans(17))
          .textContentType(.givenName)
          .submitLabel(.done)
          .onSubmit(save)
          .padding(16)
          .background(.white)
          .overlay(Rectangle().stroke(Theme.line, lineWidth: 1))
          .onChange(of: name) { saveFailed = false }
      }
      .padding(.top, 28)

      if saveFailed {
        Text("Couldn't save your name. Check your connection and try again.")
          .font(Theme.sans(13))
          .foregroundStyle(Theme.accent)
          .padding(.top, 12)
      }

      Spacer()

      Button(action: save) {
        Group {
          if isSaving {
            ProgressView().tint(.white)
          } else {
            Text("Continue")
          }
        }
        .font(Theme.sans(15, .medium))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Theme.ink)
      }
      .buttonStyle(.plain)
      .disabled(trimmedName.isEmpty || isSaving)
      .opacity(trimmedName.isEmpty ? 0.4 : 1)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Theme.paper)
    .foregroundStyle(Theme.ink)
  }

  private func save() {
    guard !trimmedName.isEmpty, !isSaving else { return }
    isSaving = true
    saveFailed = false
    Task {
      let saved = await model.createProfile(displayName: trimmedName)
      isSaving = false
      saveFailed = !saved
    }
  }
}
