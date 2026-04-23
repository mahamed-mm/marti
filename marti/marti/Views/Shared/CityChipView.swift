import SwiftUI

struct CityChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.martiLabel2)
                .foregroundStyle(isSelected ? Color.canvas : Color.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(isSelected ? Color.coreAccent : Color.surfaceElevated)
                )
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    HStack {
        CityChipView(title: "All", isSelected: true, action: {})
        CityChipView(title: "Mogadishu", isSelected: false, action: {})
        CityChipView(title: "Hargeisa", isSelected: false, action: {})
    }
    .padding()
    .background(Color.canvas)
}
