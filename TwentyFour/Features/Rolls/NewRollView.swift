import Supabase
import SwiftUI

struct NewRollView: View {
  @State private var name: String = ""
  @State private var location: String = ""
  @Environment(\.dismiss) private var dismiss
  @State private var isCreating = false
  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespaces)
  }
  private var locationOrNil: String? {
    let trimmed = location.trimmingCharacters(in: .whitespaces)
    return trimmed.isEmpty ? nil : trimmed
  }
  var body: some View {
    NavigationStack {
      ZStack {
        Theme.paper.ignoresSafeArea()

        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 4) {
            Text("New roll")
              .font(Theme.sans(30))
            Text("24 frames. Develops when the roll is full.")
              .font(Theme.sans(14))
              .foregroundStyle(Theme.muted)
          }
          .padding(.bottom, 12)
          VStack(alignment: .leading, spacing: 6) {
            Text("Name")
              .metaStyle(9)
            TextField("Kento's birthday", text: $name)
              .font(Theme.sans(17))
              .padding(16)
              .background(.white)
              .overlay(Rectangle().stroke(Theme.line, lineWidth: 1))
          }
          VStack(alignment: .leading, spacing: 6) {
            Text("Location (optional)")
              .metaStyle(9)
            TextField("Shibuya", text: $location)
              .font(Theme.sans(17))
              .padding(16)
              .background(.white)
              .overlay(Rectangle().stroke(Theme.line, lineWidth: 1))
          }
          Spacer()

          Button {
            isCreating = true
            Task {
              do {
                try await SupabaseClient.shared.rpc(
                  "create_roll",
                  params: CreateRollParams(p_name: trimmedName, p_location: locationOrNil)
                )
                .execute()
                dismiss()
              } catch {
                print("Failed to create roll:", error)
                isCreating = false
              }
            }
          } label: {
            Group {
              if isCreating {
                ProgressView()
                  .tint(.white)
              } else {
                Text("Create roll")
              }
            }
            .font(Theme.sans(15, .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.ink)
          }
          .buttonStyle(.plain)
          .disabled(trimmedName.isEmpty || isCreating)
          .opacity(trimmedName.isEmpty ? 0.4 : 1)
        }
        .padding(24)
        .foregroundStyle(Theme.ink)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Theme.paper, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .font(Theme.sans(15))
          .foregroundStyle(Theme.muted)
          .disabled(isCreating)
        }
        ToolbarItem(placement: .principal) {
          Text("TwentyFour")
            .font(Theme.sans(13, .bold))
            .textCase(.uppercase)
            .tracking(0.5)
        }
      }
    }
  }
}

struct CreateRollParams: Encodable {
  let p_name: String
  let p_location: String?
}
