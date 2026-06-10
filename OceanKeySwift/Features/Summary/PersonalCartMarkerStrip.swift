import SwiftUI

struct PersonalCartMarkerStrip: View {
    let markers: PersonalCartMarkers
    let building: Building
    let onTap: (PersonalCartMarkerSlot) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(slots) { slot in
                PersonalCartMarkerButton(
                    slot: slot,
                    floor: markers.floor(for: slot),
                    action: { onTap(slot) }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Метки персональных тележек")
    }

    private var slots: [PersonalCartMarkerSlot] {
        PersonalCartMarkers.slots.filter { $0.building == building }
    }
}

private struct PersonalCartMarkerButton: View {
    let slot: PersonalCartMarkerSlot
    let floor: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(foreground)
                .frame(width: 34, height: 26)
                .background(fill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.white.opacity(floor == nil ? 0.22 : 0.34), lineWidth: 1)
                }
                .shadow(color: fill.opacity(0.28), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private var label: String {
        if let floor {
            "\(floor)"
        } else {
            "-"
        }
    }

    private var accessibilityText: String {
        if let floor {
            "\(slot.title), этаж \(floor)"
        } else {
            "\(slot.title), этаж не выбран"
        }
    }

    private var fill: Color {
        switch slot.tone {
        case .yellow:
            Color(hex: 0xFFD83D)
        case .gray:
            Color(hex: 0x9DA3A6)
        }
    }

    private var foreground: Color {
        switch slot.tone {
        case .yellow:
            Color.black.opacity(0.88)
        case .gray:
            Color.white
        }
    }
}

#Preview {
    PersonalCartMarkerStrip(
        markers: PersonalCartMarkers(
            aYellowFloor: 3,
            aGrayFloor: nil,
            bYellowFloor: 5,
            bGrayFloor: 2
        ),
        building: .a,
        onTap: { _ in }
    )
    .padding()
    .background(OceanKeyTheme.background)
}
