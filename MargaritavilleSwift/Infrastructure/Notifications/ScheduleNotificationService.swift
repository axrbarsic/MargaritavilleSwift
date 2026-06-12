import SwiftUI
import UserNotifications

struct ScheduleNotificationClient: Sendable {
    let scheduleRoom: @MainActor @Sendable (_ roomID: RoomCell.ID, _ dueAt: Date) -> Void
    let cancelRoom: @MainActor @Sendable (_ roomID: RoomCell.ID) -> Void

    static let noop = ScheduleNotificationClient(
        scheduleRoom: { _, _ in },
        cancelRoom: { _ in }
    )

    static func live(_ service: LocalScheduleNotificationService) -> ScheduleNotificationClient {
        ScheduleNotificationClient(
            scheduleRoom: { roomID, dueAt in service.scheduleRoom(roomID: roomID, dueAt: dueAt) },
            cancelRoom: { roomID in service.cancelRoom(roomID: roomID) }
        )
    }
}

@MainActor
final class LocalScheduleNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var requestedAuthorization = false

    override init() {
        super.init()
        center.delegate = self
    }

    func scheduleRoom(roomID: RoomCell.ID, dueAt: Date) {
        requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = AppIdentity.scheduleNotificationTitle
        content.body = "Room \(roomID) opened at \(RoomScheduleSelection(date: dueAt).displayLabel)"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueAt),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: notificationID(for: roomID),
            content: content,
            trigger: trigger
        )
        center.removePendingNotificationRequests(withIdentifiers: [notificationID(for: roomID)])
        center.add(request)
    }

    func cancelRoom(roomID: RoomCell.ID) {
        let id = notificationID(for: roomID)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    private func requestAuthorizationIfNeeded() {
        guard !requestedAuthorization else { return }
        requestedAuthorization = true
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notificationID(for roomID: RoomCell.ID) -> String {
        "\(AppIdentity.scheduleNotificationIdentifierPrefix).\(roomID)"
    }
}

private struct ScheduleNotificationEnvironmentKey: EnvironmentKey {
    static let defaultValue = ScheduleNotificationClient.noop
}

extension EnvironmentValues {
    var scheduleNotifications: ScheduleNotificationClient {
        get { self[ScheduleNotificationEnvironmentKey.self] }
        set { self[ScheduleNotificationEnvironmentKey.self] = newValue }
    }
}
