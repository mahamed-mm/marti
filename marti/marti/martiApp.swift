//
//  MartiApp.swift
//  Marti
//
//  Created by Mahamed Mahad on 17/04/2026.
//

import SwiftUI
import SwiftData
import Supabase

@main
struct MartiApp: App {
    private let listingService: ListingService
    private let currencyService: CurrencyService

    init() {
        MapboxConfig.configure()
        let supabase = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
        self.listingService = SupabaseListingService(client: supabase)
        self.currencyService = LiveCurrencyService()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                listingService: listingService,
                currencyService: currencyService
            )
        }
        .modelContainer(for: [Listing.self, DiscoveryCategory.self])
    }
}
