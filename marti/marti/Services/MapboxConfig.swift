import Foundation
import MapboxMaps

enum MapboxConfig {
    static let accessToken: String = {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String,
              !token.isEmpty
        else {
            fatalError("MBXAccessToken missing in Info.plist")
        }
        return token
    }()

    static func configure() {
        MapboxOptions.accessToken = accessToken
    }
}
