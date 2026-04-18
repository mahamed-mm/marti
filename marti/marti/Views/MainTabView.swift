import SwiftUI
import SwiftData

struct MainTabView: View {
    let listingService: ListingService
    let currencyService: CurrencyService
    @State private var auth = AuthManager()
    @State private var selection: TabKind = .discover
    @Environment(\.modelContext) private var modelContext

    enum TabKind: Hashable, CaseIterable, FloatingTabProtocol {
        case discover, saved, bookings, messages, profile

        var title: String {
            switch self {
            case .discover: "Discover"
            case .saved:    "Saved"
            case .bookings: "Bookings"
            case .messages: "Messages"
            case .profile:  "Profile"
            }
        }

        var systemImage: String {
            switch self {
            case .discover: "magnifyingglass"
            case .saved:    "heart"
            case .bookings: "calendar"
            case .messages: "bubble.left"
            case .profile:  "person"
            }
        }
    }

    var body: some View {
        FloatingTabView(selection: $selection) { tab, tabBarHeight in
            switch tab {
            case .discover:
                NavigationStack {
                    DiscoveryView(
                        viewModel: ListingDiscoveryViewModel(
                            listingService: listingService,
                            currencyService: currencyService,
                            authManager: auth,
                            modelContext: modelContext
                        )
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
            case .saved:
                NavigationStack { ComingSoonView(title: "Saved") }
            case .bookings:
                NavigationStack { ComingSoonView(title: "Bookings") }
            case .messages:
                NavigationStack { ComingSoonView(title: "Messages") }
            case .profile:
                NavigationStack { ComingSoonView(title: "Profile") }
            }
        }
        .environment(auth)
        .environment(\.currencyService, currencyService)
        .preferredColorScheme(.dark)
    }
}

private struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: Spacing.base) {
            Image(systemName: "hammer")
                .font(.system(size: 32))
                .foregroundStyle(Color.textTertiary)
            Text(title)
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
            Text("Coming soon")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
        .navigationTitle(title)
    }
}
