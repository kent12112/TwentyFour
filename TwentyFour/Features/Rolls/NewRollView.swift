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
              .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("24 shots. Develops when full.")
              .font(.system(size: 13, design: .rounded))
              .foregroundStyle(Theme.ink.opacity(0.6))
          }
          VStack(alignment: .leading, spacing: 6) {
            Text("NAME")
              .font(.system(size: 11, weight: .semibold, design: .monospaced))
              .foregroundStyle(Theme.ink.opacity(0.6))
            TextField("Kento's birthday", text: $name)
              .padding()
              .background(.white, in: RoundedRectangle(cornerRadius: 12))
          }
          VStack(alignment: .leading, spacing: 6) {
            Text("LOCATION (optional)")
              .font(.system(size: 11, weight: .semibold, design: .monospaced))
              .foregroundStyle(Theme.ink.opacity(0.6))
            TextField("Shibuya", text: $location)
              .padding()
              .background(.white, in: RoundedRectangle(cornerRadius: 12))
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
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 12))
          }
          .buttonStyle(.plain)
          .disabled(trimmedName.isEmpty || isCreating)
          .opacity(trimmedName.isEmpty ? 0.4 : 1)
        }
        .padding(24)
        .foregroundStyle(Theme.ink)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .disabled(isCreating)
        }
      }
    }
  }
}

struct CreateRollParams: Encodable {
  let p_name: String
  let p_location: String?
}
