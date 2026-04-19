import SwiftUI

// MARK: - Primary

/// Cyan pill CTA. Two width modes: `.content` hugs the label with `Spacing.xl`
/// horizontal padding, `.fill` stretches to the parent's width. Callers own
/// outer margins (screen-edge / sheet paddings).
struct PrimaryButtonStyle: ButtonStyle {
    enum Expansion { case content, fill }
    var expansion: Expansion = .content

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.martiLabel1)
            .foregroundStyle(Color.canvas)
            .frame(maxWidth: expansion == .fill ? .infinity : nil, minHeight: 48)
            .padding(.horizontal, expansion == .content ? Spacing.xl : 0)
            .background(Color.coreAccent)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { .init() }
    static var primaryFullWidth: PrimaryButtonStyle { .init(expansion: .fill) }
}

// MARK: - Ghost

/// Text-only `coreAccent` CTA with 44pt hit target. `.regular` uses
/// `martiLabel1`; `.compact` uses `martiLabel2` for inline helpers like the
/// filter sheet's "Clear all".
struct GhostButtonStyle: ButtonStyle {
    enum Size { case regular, compact }
    var size: Size = .regular

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .regular ? .martiLabel1 : .martiLabel2)
            .foregroundStyle(Color.coreAccent)
            .frame(minHeight: 44)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { .init() }
    static var ghostCompact: GhostButtonStyle { .init(size: .compact) }
}
