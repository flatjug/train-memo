import Foundation
import SwiftData

@Model
final class AppSettings: Identifiable {
    static let defaultNotificationHour = 20
    static let defaultNotificationMinute = 0

    @Attribute(.unique) var id: UUID
    var rotationStartDate: Date
    var notificationEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int

    init(
        id: UUID = UUID(),
        rotationStartDate: Date = Calendar.current.startOfDay(for: Date()),
        notificationEnabled: Bool = true,
        notificationHour: Int = defaultNotificationHour,
        notificationMinute: Int = defaultNotificationMinute
    ) {
        self.id = id
        self.rotationStartDate = rotationStartDate
        self.notificationEnabled = notificationEnabled
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
    }
}
