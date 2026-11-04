import Foundation

/// The Mach service the privileged helper listens on.
public let helperMachService = "xyz.pesso.unplugalarm.helper"

/// XPC interface the app uses to switch system sleep off and on through the helper.
@objc public protocol SleepControl {
    func setSleepDisabled(_ disabled: Bool, reply: @escaping @Sendable (Bool) -> Void)
}
