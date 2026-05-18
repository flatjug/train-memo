import Foundation
import SwiftData

@Model
final class AppSettings: Identifiable {
    @Attribute(.unique) var id: UUID
    var rotationStartDate: Date
    var notificationEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int

    init(
        id: UUID = UUID(),
        rotationStartDate: Date = Calendar.current.startOfDay(for: Date()),
        notificationEnabled: Bool = true,
        notificationHour: Int = 20,
        notificationMinute: Int = 0
    ) {
        self.id = id
        self.rotationStartDate = rotationStartDate
        self.notificationEnabled = notificationEnabled
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
    }
}
