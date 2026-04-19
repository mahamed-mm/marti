import SwiftUI

struct FilterSheetView: View {
    @Bindable var viewModel: ListingDiscoveryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draftCity: City?
    @State private var draftCheckIn: Date?
    @State private var draftCheckOut: Date?
    @State private var draftGuests: Int
    @State private var draftMinDollars: Int
    @State private var draftMaxDollars: Int
    @State private var pickerEditing: DateField?

    private static let priceFloor: Int = 0
    private static let priceCeiling: Int = 500
    private static let priceStep: Int = 5

    private enum DateField: String, Identifiable {
        case checkIn, checkOut
        var id: String { rawValue }
    }

    init(viewModel: ListingDiscoveryViewModel) {
        let filter = viewModel.filter
        self._viewModel = Bindable(viewModel)
        _draftCity = State(initialValue: filter.city)
        _draftCheckIn = State(initialValue: filter.checkIn)
        _draftCheckOut = State(initialValue: filter.checkOut)
        _draftGuests = State(initialValue: filter.guestCount)
        _draftMinDollars = State(initialValue: (filter.priceMin ?? 0) / 100)
        _draftMaxDollars = State(initialValue: (filter.priceMax ?? Self.priceCeiling * 100) / 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.lg)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    citySection
                    Divider().background(Color.dividerLine)

                    dateSection
                    Divider().background(Color.dividerLine)

                    guestSection
                    Divider().background(Color.dividerLine)

                    priceSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.base)
            }
        }
        .background(Color.surfaceDefault.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider().background(Color.dividerLine)
                applyButton
            }
            .background(Color.surfaceDefault.ignoresSafeArea(edges: .bottom))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.surfaceDefault)
        .sheet(item: $pickerEditing) { field in
            datePickerSheet(for: field)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        // Fall back to a stacked layout at large Dynamic Type sizes so the
        // title and action don't collide or truncate on narrow widths.
        ViewThatFits(in: .horizontal) {
            HStack {
                headerTitle
                Spacer()
                clearAllButton
            }
            VStack(alignment: .leading, spacing: Spacing.md) {
                headerTitle
                clearAllButton
            }
        }
    }

    private var headerTitle: some View {
        Text("Filters")
            .font(.martiHeading4)
            .foregroundStyle(Color.textPrimary)
    }

    private var clearAllButton: some View {
        Button("Clear all", action: clearAll)
            .buttonStyle(.ghostCompact)
            .accessibilityLabel("Clear all filters")
    }

    // MARK: - City

    private var citySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            label("CITY")
            HStack(spacing: Spacing.md) {
                cityButton(.mogadishu)
                cityButton(.hargeisa)
            }
        }
    }

    private func cityButton(_ city: City) -> some View {
        Button {
            draftCity = (draftCity == city) ? nil : city
        } label: {
            Text(city.rawValue)
                .font(.martiLabel2)
                .foregroundStyle(draftCity == city ? Color.canvas : Color.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    Capsule().fill(draftCity == city ? Color.coreAccent : Color.surfaceElevated)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dates

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            label("DATES")
            HStack(spacing: Spacing.md) {
                datePill(title: dateString(draftCheckIn) ?? "Check-in", isSet: draftCheckIn != nil) {
                    if draftCheckIn == nil {
                        draftCheckIn = Date()
                    }
                    pickerEditing = .checkIn
                }
                Text("to")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textTertiary)
                datePill(title: dateString(draftCheckOut) ?? "Check-out", isSet: draftCheckOut != nil) {
                    if draftCheckOut == nil {
                        let base = draftCheckIn ?? Date()
                        draftCheckOut = Calendar.current.date(byAdding: .day, value: 2, to: base)
                    }
                    pickerEditing = .checkOut
                }
            }

            if draftCheckIn != nil || draftCheckOut != nil {
                Button("Clear dates") {
                    draftCheckIn = nil
                    draftCheckOut = nil
                }
                .font(.martiLabel2)
                .foregroundStyle(Color.textTertiary)
            }
        }
    }

    private func datePill(title: String, isSet: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.martiLabel2)
                .foregroundStyle(isSet ? Color.textPrimary : Color.textTertiary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: Radius.sm).fill(Color.surfaceElevated)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func datePickerSheet(for field: DateField) -> some View {
        let binding = Binding<Date>(
            get: {
                switch field {
                case .checkIn:  return draftCheckIn ?? Date()
                case .checkOut: return draftCheckOut ?? Date().addingTimeInterval(86_400 * 2)
                }
            },
            set: { newValue in
                switch field {
                case .checkIn:  draftCheckIn = newValue
                case .checkOut: draftCheckOut = newValue
                }
            }
        )
        VStack(spacing: 0) {
            DatePicker(
                field == .checkIn ? "Check-in" : "Check-out",
                selection: binding,
                in: field == .checkIn ? Date()... : (draftCheckIn ?? Date())...,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.coreAccent)
            .padding(Spacing.base)
            Spacer(minLength: 0)
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.surfaceDefault)
    }

    private func dateString(_ date: Date?) -> String? {
        guard let date else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

    // MARK: - Guests

    private var guestSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            label("GUESTS")
            HStack {
                Text("\(draftGuests) guest\(draftGuests == 1 ? "" : "s")")
                    .font(.martiBody)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                stepper
            }
        }
    }

    private var stepper: some View {
        HStack(spacing: Spacing.base) {
            stepperButton(systemImage: "minus", enabled: draftGuests > 1) {
                draftGuests = max(1, draftGuests - 1)
            }
            Text("\(draftGuests)")
                .font(.martiLabel1)
                .foregroundStyle(Color.textPrimary)
                .frame(minWidth: 24)
            stepperButton(systemImage: "plus", enabled: draftGuests < 10) {
                draftGuests = min(10, draftGuests + 1)
            }
        }
    }

    /// Outline-style stepper circle (matches 1CC-1).
    private func stepperButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? Color.textPrimary : Color.textTertiary.opacity(0.5))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(
                        enabled ? Color.textSecondary : Color.textTertiary.opacity(0.4),
                        lineWidth: 1.5
                    )
                )
                .frame(width: 44, height: 44) // 44pt hit target
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                label("PRICE RANGE")
                Spacer()
                Text("$\(draftMinDollars) – $\(draftMaxDollars)")
                    .font(.martiLabel2)
                    .foregroundStyle(Color.textPrimary)
            }
            PriceRangeSlider(
                minValue: $draftMinDollars,
                maxValue: $draftMaxDollars,
                bounds: Self.priceFloor...Self.priceCeiling,
                step: Self.priceStep
            )
        }
    }

    // MARK: - Apply

    private var applyButton: some View {
        Button("Show listings", action: apply)
            .buttonStyle(.primaryFullWidth)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.martiCaption.bold())
            .tracking(0.5)
            .foregroundStyle(Color.textTertiary)
    }

    private func clearAll() {
        draftCity = nil
        draftCheckIn = nil
        draftCheckOut = nil
        draftGuests = 1
        draftMinDollars = Self.priceFloor
        draftMaxDollars = Self.priceCeiling
    }

    private func apply() {
        let priceMin = draftMinDollars > Self.priceFloor ? draftMinDollars * 100 : nil
        let priceMax = draftMaxDollars < Self.priceCeiling ? draftMaxDollars * 100 : nil
        let filter = ListingFilter(
            city: draftCity,
            checkIn: draftCheckIn,
            checkOut: draftCheckOut,
            guestCount: draftGuests,
            priceMin: priceMin,
            priceMax: priceMax
        )
        viewModel.applyFilter(filter)
        dismiss()
    }
}
