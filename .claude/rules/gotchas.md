# Project-specific gotchas

- **Prices = Int USD cents.** `8500` = `$85.00`. No float math on money.
- **Dual currency display.** Cards show abbreviated SOS (`~1.5M SOS`); detail/booking show full (`~1,530,000 SOS`). Route through `LiveCurrencyService.format(sos:display:)`.
- **Image cache is generic** — reused by any remote-image view, not listing-specific.
- **Supabase publishable key is public.** Committed in `Info.plist`. RLS protects data. Mapbox **secret** token lives in `~/.netrc` only.
- **Date availability filter is stubbed** — wires into `bookings` table once booking ships.
- **`Package.resolved` is committed.** Keep SPM pins stable.
- **Mapbox SPM pin = `main`.** Pin to v11 release tag before App Store submit.
- **iOS 26 quirk:** `ScrollView` inside a `Tab` with `.toolbarVisibility(.hidden, for: .tabBar)` ignores `.safeAreaInset` / `.safeAreaPadding` from ancestors. `FloatingTabView` works around this via canvas-masked home-indicator area. See `Views/Shared/FloatingTabView.swift`.
