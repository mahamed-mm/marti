import Foundation
import Supabase

enum SupabaseConfig {
    static let url: URL = {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: raw)
        else {
            fatalError("SUPABASE_URL missing or invalid in Info.plist")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty
        else {
            fatalError("SUPABASE_ANON_KEY missing in Info.plist")
        }
        return key
    }()

    static let client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
}
