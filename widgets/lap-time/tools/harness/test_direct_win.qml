import QtQuick
import org.kde.kirigami as Kirigami
import "../../contents/ui" as LapTime

LapTime.Overlay {
    id: overlay
    breakType: "stretch"
    isDark: true
    remainingSec: 275
    totalSec: 300
    snoozeMin: 5
    maxSnoozes: 3
    snoozeCount: 0
    visible: true
    width: 1920
    height: 1080
}
