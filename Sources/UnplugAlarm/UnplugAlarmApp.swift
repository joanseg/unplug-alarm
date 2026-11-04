import SwiftUI

/// Menu-bar app: arm it while plugged in; unplugging rings until disarmed.
@main
struct UnplugAlarmApp: App {
    @State private var controller = AlarmController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Unplug Alarm", systemImage: icon) {
            MenuContent(controller: controller)
        }
    }

    private var icon: String {
        if controller.isRinging { return "bell.and.waves.left.and.right.fill" }
        return controller.isArmed ? "lock.shield.fill" : "lock.open"
    }
}

struct MenuContent: View {
    let controller: AlarmController

    var body: some View {
        Text(controller.isOnAC ? "Plugged in" : "On battery")
        Divider()
        if controller.isArmed {
            Button(controller.isRinging ? "Silence and Disarm…" : "Disarm…") {
                Task { await controller.disarm() }
            }
        } else {
            Button("Arm") { controller.arm() }
                .disabled(!controller.isOnAC)
        }
        Divider()
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .disabled(controller.isArmed)
    }
}
