import SwiftUI

/// Dual-thumb slider for selecting a min/max integer range. Values are USD dollars
/// (the surrounding view converts to cents before storing in the filter).
struct PriceRangeSlider: View {
    @Binding var minValue: Int
    @Binding var maxValue: Int
    let bounds: ClosedRange<Int>
    let step: Int

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let total = CGFloat(bounds.upperBound - bounds.lowerBound)
            let minOffset = CGFloat(minValue - bounds.lowerBound) / total * width
            let maxOffset = CGFloat(maxValue - bounds.lowerBound) / total * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.surfaceElevated)
                    .frame(height: trackHeight)
                    .frame(maxHeight: .infinity, alignment: .center)

                Capsule()
                    .fill(Color.coreAccent)
                    .frame(width: max(0, maxOffset - minOffset), height: trackHeight)
                    .offset(x: minOffset)
                    .frame(maxHeight: .infinity, alignment: .center)

                thumb()
                    .position(x: minOffset, y: geo.size.height / 2)
                    .gesture(dragGesture(width: width, isMin: true))
                    .accessibilityLabel("Minimum price")
                    .accessibilityValue("$\(minValue)")
                    .accessibilityAdjustableAction { direction in
                        adjust(isMin: true, direction: direction)
                    }

                thumb()
                    .position(x: maxOffset, y: geo.size.height / 2)
                    .gesture(dragGesture(width: width, isMin: false))
                    .accessibilityLabel("Maximum price")
                    .accessibilityValue("$\(maxValue)")
                    .accessibilityAdjustableAction { direction in
                        adjust(isMin: false, direction: direction)
                    }
            }
        }
        .frame(height: 44) // 44pt tap-target band
    }

    private func thumb() -> some View {
        Circle()
            .fill(Color.coreAccent)
            .frame(width: thumbSize, height: thumbSize)
            .overlay(
                Circle().stroke(Color.canvas, lineWidth: 2)
            )
            .frame(width: 44, height: 44) // hit area
            .contentShape(Circle())
    }

    private func dragGesture(width: CGFloat, isMin: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let total = CGFloat(bounds.upperBound - bounds.lowerBound)
                let raw = Int((value.location.x / max(width, 1)) * total) + bounds.lowerBound
                let snapped = snap(raw)
                if isMin {
                    minValue = min(snapped, maxValue - step)
                } else {
                    maxValue = max(snapped, minValue + step)
                }
            }
    }

    private func snap(_ raw: Int) -> Int {
        let clamped = min(max(raw, bounds.lowerBound), bounds.upperBound)
        return Int((Double(clamped) / Double(step)).rounded()) * step
    }

    private func adjust(isMin: Bool, direction: AccessibilityAdjustmentDirection) {
        let delta = direction == .increment ? step : -step
        if isMin {
            let next = min(max(minValue + delta, bounds.lowerBound), maxValue - step)
            minValue = next
        } else {
            let next = max(min(maxValue + delta, bounds.upperBound), minValue + step)
            maxValue = next
        }
    }
}
