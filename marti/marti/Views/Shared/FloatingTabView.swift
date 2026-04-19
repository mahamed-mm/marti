import SwiftUI

// MARK: - Protocol

/// Any enum used with `FloatingTabView` must conform to this protocol so the
/// bar can render a title + SF Symbol for each case.
protocol FloatingTabProtocol {
    var title: String { get }
    var systemImage: String { get }
}

// MARK: - Config

struct FloatingTabConfig {
    var activeTint: Color = .coreAccent
    var inactiveTint: Color = .textTertiary
    var background: Color = .surfaceDefault
    var outerHorizontalPadding: CGFloat = 16
    var outerBottomPadding: CGFloat = 8
    var innerHorizontalPadding: CGFloat = 24
    var innerVerticalPadding: CGFloat = 10
    var animation: Animation = .smooth(duration: 0.35, extraBounce: 0)
    var shadowRadius: CGFloat = 0
    var iconPointSize: CGFloat = 20
    var labelPointSize: CGFloat = 10
}

// MARK: - Hide helper

/// Shared state so any view in the `FloatingTabView`'s subtree can toggle bar
/// visibility via `.hideFloatingTabBar(true)`.
@Observable
@MainActor
final class FloatingTabViewHelper {
    var hideTabBar: Bool = false
}

private struct HideFloatingTabBarModifier: ViewModifier {
    let status: Bool
    @Environment(FloatingTabViewHelper.self) private var helper

    func body(content: Content) -> some View {
        content.onChange(of: status, initial: true) { _, newValue in
            helper.hideTabBar = newValue
        }
    }
}

extension View {
    /// Slide the floating tab bar offscreen from any view inside the container.
    /// Use this on pushed detail screens that should take the full height.
    func hideFloatingTabBar(_ status: Bool) -> some View {
        modifier(HideFloatingTabBarModifier(status: status))
    }
}

// MARK: - Container

/// A generic floating tab-bar container. Wraps a SwiftUI `TabView` (iOS 18+ API),
/// hides the native tab bar, overlays a custom bar, and passes the bar's measured
/// height into the tab content closure so scroll views can size their safe-area
/// insets correctly.
struct FloatingTabView<Content: View, Value: CaseIterable & Hashable & FloatingTabProtocol>: View where Value.AllCases: RandomAccessCollection {
    var config: FloatingTabConfig
    @Binding var selection: Value
    var content: (Value, CGFloat) -> Content

    @State private var tabBarSize: CGSize = .zero
    @State private var helper = FloatingTabViewHelper()

    init(
        config: FloatingTabConfig = .init(),
        selection: Binding<Value>,
        @ViewBuilder content: @escaping (Value, CGFloat) -> Content
    ) {
        self.config = config
        self._selection = selection
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                ForEach(Value.allCases, id: \.hashValue) { tab in
                    Tab(value: tab) {
                        content(tab, tabBarSize.height)
                            .toolbarVisibility(.hidden, for: .tabBar)
                    }
                }
            }

            FloatingTabBar(config: config, activeTab: $selection)
                .padding(.horizontal, config.outerHorizontalPadding)
                .padding(.bottom, config.outerBottomPadding)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    tabBarSize = newValue
                }
                .opacity(helper.hideTabBar ? 0 : 1)
                .allowsHitTesting(!helper.hideTabBar)
                .accessibilityHidden(helper.hideTabBar)
                .animation(.easeInOut(duration: 0.25), value: helper.hideTabBar)
        }
        .environment(helper)
    }
}

// MARK: - Bar chrome

/// Renders the Marti floating bar: surfaceDefault capsule with icon-over-label
/// tabs, `coreAccent` active tint, subtle symbol-bounce on tap, and a haptic.
private struct FloatingTabBar<Value: CaseIterable & Hashable & FloatingTabProtocol>: View where Value.AllCases: RandomAccessCollection {
    let config: FloatingTabConfig
    @Binding var activeTab: Value
    @State private var toggleSymbolEffect: [Bool] = Array(repeating: false, count: Value.allCases.count)
    @State private var hapticsTrigger: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Value.allCases.enumerated()), id: \.element.hashValue) { index, tab in
                tabItem(tab: tab, index: index, isActive: activeTab == tab)
            }
        }
        .padding(.horizontal, config.innerHorizontalPadding)
        .padding(.vertical, config.innerVerticalPadding)
        .background {
            // Material blur lets content scrolling underneath show through softly,
            // tinted with a translucent surfaceDefault layer for the dark aesthetic.
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule().fill(config.background.opacity(0.5))
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        .animation(config.animation, value: activeTab)
        .sensoryFeedback(.impact, trigger: hapticsTrigger)
    }

    private func tabItem(tab: Value, index: Int, isActive: Bool) -> some View {
        Button {
            guard activeTab != tab else { return }
            activeTab = tab
            toggleSymbolEffect[index].toggle()
            hapticsTrigger.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: config.iconPointSize, weight: .regular))
                    .frame(height: 24)
                    .symbolEffect(.bounce.byLayer.down, value: toggleSymbolEffect[index])
                Text(tab.title)
                    .font(.system(size: config.labelPointSize, weight: isActive ? .semibold : .medium))
            }
            .foregroundStyle(isActive ? config.activeTint : config.inactiveTint)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}
