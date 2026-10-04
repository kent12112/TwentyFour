import SwiftUI
import Supabase

struct NewRollView: View {
  @State private var name: String = ""
  @State private var location: String = ""
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    Form {
      TextField("Roll name", text: $name)
      TextField("Location", text: $location)
    
      Button("Create") {
        Task {
          do {
             try await SupabaseClient.shared.rpc("create_roll", params:CreateRollParams(p_name: name, p_location: location))
              .execute()
             dismiss()
          } catch {
            print("Failed to create roll:", error)
          }
         
        }
      }.disabled(name.isEmpty)
    }
  }
}

struct CreateRollParams: Encodable {
  let p_name: String
  let p_location: String?
}