import SwiftUI

struct SettingsTestDataSection: View {
    @Bindable var workSession: WorkSessionStore
    let housekeepers: [Housekeeper]

    @Environment(\.interactionFeedback) private var feedback
    @State private var latestSummary: TestWorkAssignmentSummary?

    var body: some View {
        SettingsPanel(
            title: "Тестовые данные",
            subtitle: "Быстро заполняет рабочий экран полным набором номеров."
        ) {
            Button(action: assignAllRooms) {
                SettingsInfoRow(
                    title: "Распределить весь отель",
                    value: summaryLabel,
                    systemName: "shuffle.circle.fill",
                    subtitle: "Случайно и равномерно назначает все номера всем уборщицам из списка."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var summaryLabel: String {
        guard let latestSummary else { return "Запустить" }
        return "\(latestSummary.housekeeperCount) / \(latestSummary.roomCount)"
    }

    private func assignAllRooms() {
        guard let summary = workSession.assignAllRoomsForTesting(housekeepers: housekeepers) else {
            feedback.invalid()
            return
        }
        latestSummary = summary
        feedback.confirm()
    }
}
