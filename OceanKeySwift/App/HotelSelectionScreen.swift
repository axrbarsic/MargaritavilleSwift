import SwiftUI

struct HotelSelectionScreen: View {
    let onSelect: (HotelProfile) -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 54)
                header
                VStack(spacing: 14) {
                    ForEach(HotelProfile.all) { profile in
                        hotelCard(profile)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Выбери отель")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text("Данные каждого отеля хранятся отдельно.")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
        }
    }

    private func hotelCard(_ profile: HotelProfile) -> some View {
        Button {
            onSelect(profile)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: profile.iconSystemName)
                    .font(.system(size: 30, weight: .black))
                    .frame(width: 62, height: 62)
                    .foregroundStyle(OceanKeyTheme.accent)
                    .background(.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.name)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(profile.subtitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }
            .padding(18)
            .background(OceanKeyTheme.surface.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.24), lineWidth: 1.4)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension HotelProfile {
    var iconSystemName: String {
        id == HotelProfile.margaritaville.id ? "square.grid.2x2.fill" : "list.bullet.rectangle.fill"
    }

    var subtitle: String {
        switch workflowKind {
        case .tasksSLB:
            "S / L / B, текущая логика OceanKey"
        case .simpleCycle:
            "Жёлтый → красный → зелёный, сетка 4 колонки"
        }
    }
}

#Preview {
    HotelSelectionScreen { _ in }
        .preferredColorScheme(.dark)
}
