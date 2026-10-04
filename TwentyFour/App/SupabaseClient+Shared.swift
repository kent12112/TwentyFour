import Foundation
import Supabase

extension SupabaseClient {
  static let shared: SupabaseClient = {
    guard
      let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
      let url = URL(string: urlString),
      let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String
    else {
      fatalError("Supabase URL or Key not found in Info.plist")
    }
    return SupabaseClient(supabaseURL: url, supabaseKey: key, options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true)))
  }()
}