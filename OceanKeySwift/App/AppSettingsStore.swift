import Foundation
import Observation

@Observable
final class AppSettingsStore {
    private enum Keys {
        static let roomCellGeometry = "roomCellGeometry"
        static let roomTaskLongPress = "roomTaskLongPress"
        static let matrixColorRichness = "matrixColorRichness"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    private var storedMatrixColorRichness: Double

    var roomCellGeometry: RoomCellGeometry {
        didSet {
            userDefaults.set(roomCellGeometry.rawValue, forKey: Keys.roomCellGeometry)
        }
    }

    var roomTaskLongPress: Bool {
        didSet {
            userDefaults.set(roomTaskLongPress, forKey: Keys.roomTaskLongPress)
        }
    }

    var matrixColorRichness: Double {
        get { storedMatrixColorRichness }
        set {
            storedMatrixColorRichness = Self.normalizedMatrixColorRichness(newValue)
            userDefaults.set(storedMatrixColorRichness, forKey: Keys.matrixColorRichness)
        }
    }

    var matrixConfiguration: MatrixRainConfiguration {
        MatrixRainConfiguration(colorRichness: matrixColorRichness)
    }

    init(
        roomCellGeometry: RoomCellGeometry = .roomy,
        roomTaskLongPress: Bool = true,
        matrixColorRichness: Double = MatrixRainConfiguration.default.colorRichness,
        userDefaults: UserDefaults = .standard
    ) {
        self.roomCellGeometry = roomCellGeometry
        self.roomTaskLongPress = roomTaskLongPress
        self.storedMatrixColorRichness = Self.normalizedMatrixColorRichness(matrixColorRichness)
        self.userDefaults = userDefaults
    }

    static func load(userDefaults: UserDefaults = .standard) -> AppSettingsStore {
        let rawValue = userDefaults.string(forKey: Keys.roomCellGeometry)
        let geometry = rawValue.flatMap(RoomCellGeometry.init(rawValue:)) ?? .roomy
        let roomTaskLongPress = userDefaults.object(forKey: Keys.roomTaskLongPress) as? Bool ?? true
        let matrixColorRichness = userDefaults.object(forKey: Keys.matrixColorRichness) as? Double
            ?? MatrixRainConfiguration.default.colorRichness
        return AppSettingsStore(
            roomCellGeometry: geometry,
            roomTaskLongPress: roomTaskLongPress,
            matrixColorRichness: matrixColorRichness,
            userDefaults: userDefaults
        )
    }

    static func normalizedMatrixColorRichness(_ value: Double) -> Double {
        min(max(value, 0.65), 2.40)
    }
}
