import SwiftUI

struct CityChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.martiLabel2)
                .foregroundStyle(isSelected ? Color.canvas : Color.textSecondary)
                .padding(.horizontal, Spacing.base)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(isSelected ? Color.coreAccent : Color.surfaceElevated)
                )
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
