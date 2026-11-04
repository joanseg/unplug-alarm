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
        if controller.isArmed {
            if controller.isLidProtected {
                Text("Lid closed: protected")
            } else {
                Button("Lid closed: not protected — approve helper…") { controller.sleepGuard.openLoginItems() }
            }
        }
        Divider()
        if controller.isArmed {
            Button(controller.isRinging ? "Silence and Disarm…" : "Disarm…") {
                Task { await controller.disarm() }
            }
        } else {
            Button("Arm") { Task { await controller.arm() } }
                .disabled(!controller.isOnAC)
        }
        Picker("Alarm Volume", selection: Bindable(controller).volume) {
            ForEach([10, 25, 50, 75, 100], id: \.self) { Text("\($0)%").tag($0) }
        }
        .disabled(controller.isArmed)
        Divider()
        Button("Uninstall Unplug Alarm…") { Task { await Uninstaller.run(sleepGuard: controller.sleepGuard) } }
            .disabled(controller.isArmed)
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .disabled(controller.isArmed)
    }
}
