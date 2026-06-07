import SwiftUI

struct RoomScheduleSheet: View {
    let route: RoomScheduleRoute
    let onSet: (RoomCell.ID, Date) -> Void
    let onClear: (RoomCell.ID) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @State private var selection: RoomScheduleSelection

    init(
        route: RoomScheduleRoute,
        onSet: @escaping (RoomCell.ID, Date) -> Void,
        onClear: @escaping (RoomCell.ID) -> Void
    ) {
        self.route = route
        self.onSet = onSet
        self.onClear = onClear
        _selection = State(
            initialValue: route.initialDate.map { RoomScheduleSelection(date: $0) }
                ?? RoomScheduleSelection.defaultSelection()
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            wheelPanel
            actionRow
        }
        .padding(18)
        .background(OceanKeyTheme.surface)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Время открытия")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Комната \(route.roomID)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }
            Spacer()
            Text(selection.displayLabel)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.roomForeground)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(OceanKeyTheme.scheduled)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    private var wheelPanel: some View {
        HStack(spacing: 8) {
            schedulePicker("Час", values: RoomScheduleSelection.hours, selection: $selection.hour) { "\($0)" }
            schedulePicker("Мин", values: RoomScheduleSelection.minutes, selection: $selection.minute) {
                String(format: "%02d", $0)
            }
            periodPicker
        }
        .padding(10)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.scheduled.opacity(0.42), lineWidth: 1)
        }
    }

    private var periodPicker: some View {
        Picker("AM/PM", selection: $selection.period) {
            ForEach(RoomSchedulePeriod.allCases) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .frame(height: 142)
        .clipped()
        .onChange(of: selection.period) { _, _ in feedback.tap() }
    }

    private func schedulePicker(
        _ title: String,
        values: [Int],
        selection: Binding<Int>,
        label: @escaping (Int) -> String
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(label(value)).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .frame(height: 142)
        .clipped()
        .onChange(of: selection.wrappedValue) { _, _ in feedback.tap() }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: clearSchedule) {
                Text("Очистить")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)

            Button(action: setSchedule) {
                Text("Установить")
                    .fontWeight(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(OceanKeyTheme.scheduled)
            .foregroundStyle(OceanKeyTheme.roomForeground)
        }
    }

    private func clearSchedule() {
        feedback.deselect()
        onClear(route.roomID)
        dismiss()
    }

    private func setSchedule() {
        feedback.confirm()
        onSet(route.roomID, selection.dateToday())
        dismiss()
    }
}

#Preview {
    RoomScheduleSheet(
        route: RoomScheduleRoute(roomID: "306", initialDate: Date()),
        onSet: { _, _ in },
        onClear: { _ in }
    )
    .preferredColorScheme(.dark)
}
