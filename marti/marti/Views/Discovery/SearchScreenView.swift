import SwiftUI

/// Full-screen search surface: WHERE focused field, suggested destinations,
/// WHEN/WHO rows, and a bottom action bar. Commits a `ListingFilter` to its
/// parent via the `onSearch` closure supplied at construction.
struct SearchScreenView: View {
    @State private var viewModel: SearchScreenViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isDestinationFocused: Bool
    /// Gates the initial keyboard focus so re-appearing from WHEN/WHO sheets
    /// doesn't re-pop the keyboard on return.
    @State private var hasAppeared = false

    /// Curated destinations shown in the SUGGESTED section. Static because the
    /// list is a product decision, not data — unsupported cities render as
    /// empty states in Discovery until listings exist there.
    private let suggestions: [(City, String)] = [
        (.mogadishu, "Capital · Beaches, markets"),
        (.hargeisa,  "Somaliland · Mountain air"),
        (.kismayo,   "Southern coast"),
        (.garowe,    "Puntland"),
        (.berbera,   "Port city"),
    ]

    init(initialFilter: ListingFilter, onSearch: @escaping (ListingFilter) -> Void) {
        _viewModel = State(initialValue: SearchScreenViewModel(
            initialFilter: initialFilter,
            onSearch: onSearch
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    destinationField
                    suggestedSection
                    whenRow
                    whoRow
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.top, Spacing.base)
                .padding(.bottom, Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .background(Color.canvas.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.isWhenSheetPresented) { whenSheet }
        .sheet(isPresented: $viewModel.isWhoSheetPresented) { whoSheet }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.committedSearchCount)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            isDestinationFocused = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .glassDisc(diameter: 40)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()
            Text("Search")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
            Spacer()

            // Invisible 44pt balancer keeps the title optically centered.
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - WHERE

    private var destinationField: some View {
        @Bindable var vm = viewModel
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("WHERE")
                .font(.martiCaption)
                .foregroundStyle(Color.coreAccent)
            HStack(spacing: Spacing.md) {
                TextField("Where to?", text: $vm.destinationText)
                    .font(.martiHeading5)
                    .foregroundStyle(Color.textPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .focused($isDestinationFocused)
                    .onSubmit {
                        viewModel.commitSearch()
                        dismiss()
                    }
                if !viewModel.destinationText.isEmpty {
                    Button(action: { viewModel.clearDestination() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear destination")
                }
            }
        }
        .padding(Spacing.base)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.surfaceDefault))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(isDestinationFocused ? Color.coreAccent : Color.clear, lineWidth: 1.5)
        )
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isDestinationFocused)
    }

    // MARK: - Suggested

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SUGGESTED")
                .font(.martiCaption)
                .foregroundStyle(Color.textTertiary)
                .padding(.bottom, Spacing.sm)
            VStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, entry in
                    suggestionRow(city: entry.0, subtitle: entry.1)
                    if index < suggestions.count - 1 {
                        // Inset to align with the text column, not the tile.
                        Rectangle()
                            .fill(Color.dividerLine)
                            .frame(height: 1)
                            .padding(.leading, 44 + Spacing.base)
                    }
                }
            }
        }
    }

    private func suggestionRow(city: City, subtitle: String) -> some View {
        Button {
            viewModel.selectCity(city)
            isDestinationFocused = false
        } label: {
            HStack(spacing: Spacing.base) {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.surfaceElevated)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(Color.textPrimary)
                            .accessibilityHidden(true)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.rawValue)
                        .font(.martiLabel1)
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textTertiary)
                }
                Spacer()
            }
            .padding(.vertical, Spacing.md)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(city.rawValue), \(subtitle)")
    }

    // MARK: - WHEN / WHO

    private var whenRow: some View {
        outlinedRow(
            caption: "WHEN",
            value: whenValue,
            hint: "Opens date picker",
            action: { viewModel.isWhenSheetPresented = true }
        )
    }

    private var whoRow: some View {
        outlinedRow(
            caption: "WHO",
            value: "\(viewModel.draftGuests) guest\(viewModel.draftGuests == 1 ? "" : "s")",
            hint: "Opens guest count",
            action: { viewModel.isWhoSheetPresented = true }
        )
    }

    private func outlinedRow(
        caption: String,
        value: String,
        hint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(caption)
                        .font(.martiCaption)
                        .foregroundStyle(Color.textTertiary)
                    Text(value)
                        .font(.martiLabel1)
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.base)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.surfaceDefault))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.surfaceGlass, lineWidth: 1)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(caption), \(value)")
        .accessibilityHint(hint)
    }

    private var whenValue: String {
        guard let start = viewModel.draftCheckIn, let end = viewModel.draftCheckOut else {
            return "Add dates"
        }
        // FormatStyle picks up the user locale; abbreviated month + day matches
        // the discovery header's date-range treatment without a DateFormatter
        // allocation on every read.
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(start.formatted(style)) – \(end.formatted(style))"
    }

    // MARK: - WHEN sheet

    @ViewBuilder
    private var whenSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    DatePicker(
                        "Check-in",
                        selection: Binding(
                            get: { viewModel.draftCheckIn ?? Date() },
                            set: { viewModel.draftCheckIn = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.coreAccent)

                    DatePicker(
                        "Check-out",
                        selection: Binding(
                            get: {
                                let base = viewModel.draftCheckIn ?? Date()
                                let fallback = Calendar.current.date(byAdding: .day, value: 2, to: base) ?? base
                                return viewModel.draftCheckOut ?? fallback
                            },
                            set: { viewModel.draftCheckOut = $0 }
                        ),
                        in: (viewModel.draftCheckIn ?? Date())...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.coreAccent)
                }
                .padding(Spacing.base)
            }
            .background(Color.surfaceDefault)
            .navigationTitle("When")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { viewModel.isWhenSheetPresented = false }
                        .foregroundStyle(Color.coreAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.surfaceDefault)
    }

    // MARK: - WHO sheet

    @ViewBuilder
    private var whoSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                HStack {
                    Text("\(viewModel.draftGuests) guest\(viewModel.draftGuests == 1 ? "" : "s")")
                        .font(.martiBody)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    stepper
                }
                .padding(.horizontal, Spacing.lg)
                Spacer()
            }
            .padding(.top, Spacing.lg)
            .background(Color.surfaceDefault)
            .navigationTitle("Who")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { viewModel.isWhoSheetPresented = false }
                        .foregroundStyle(Color.coreAccent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.surfaceDefault)
    }

    private var stepper: some View {
        HStack(spacing: Spacing.base) {
            stepperButton(systemImage: "minus", enabled: viewModel.draftGuests > 1) {
                viewModel.draftGuests = max(1, viewModel.draftGuests - 1)
            }
            Text("\(viewModel.draftGuests)")
                .font(.martiLabel1)
                .foregroundStyle(Color.textPrimary)
                .frame(minWidth: 24)
            stepperButton(systemImage: "plus", enabled: viewModel.draftGuests < 10) {
                viewModel.draftGuests = min(10, viewModel.draftGuests + 1)
            }
        }
    }

    private func stepperButton(
        systemImage: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? Color.textPrimary : Color.textTertiary)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(
                        enabled ? Color.textSecondary : Color.textTertiary,
                        lineWidth: 1.5
                    )
                )
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(systemImage == "minus" ? "Decrease guests" : "Increase guests")
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.dividerLine)
                .frame(height: 1)
            // Reflow to stacked layout at AX sizes where a single row would
            // collide or truncate. Keeps both actions reachable at AX5.
            ViewThatFits(in: .horizontal) {
                HStack {
                    clearAllButton
                    Spacer()
                    searchButton
                }
                VStack(spacing: Spacing.md) {
                    searchButton
                    clearAllButton
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.surfaceDefault)
    }

    private var clearAllButton: some View {
        Button(action: { viewModel.clearAll() }) {
            Text("Clear all").underline()
        }
        .buttonStyle(.ghostCompact)
        .accessibilityLabel("Clear all")
    }

    private var searchButton: some View {
        Button(action: { viewModel.commitSearch() }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
        }
        .buttonStyle(.primary)
        .accessibilityLabel("Search")
    }
}
