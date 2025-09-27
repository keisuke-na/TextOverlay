import SwiftUI
import AppKit

/// SwiftUI用のSwiftConfettiビュー
public struct SwiftConfettiView: NSViewRepresentable {
    @Binding var trigger: Bool
    let options: ConfettiOptions
    private let confettiInstance: SwiftConfetti

    public init(trigger: Binding<Bool>, options: ConfettiOptions = .default) {
        self._trigger = trigger
        self.options = options
        self.confettiInstance = SwiftConfetti.create()
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        // Coordinatorに保存
        context.coordinator.view = view
        context.coordinator.confetti = SwiftConfetti.create(canvas: view)

        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if trigger {
            Task { @MainActor in
                await context.coordinator.confetti?.fire(options)
                trigger = false
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {
        var view: NSView?
        var confetti: SwiftConfetti?
    }
}

/// SwiftConfettiのオーバーレイビュー
public struct SwiftConfettiOverlay: View {
    @State private var showConfetti = false
    private let notificationName: Notification.Name

    public init(notificationName: Notification.Name = Notification.Name("TriggerSwiftConfetti")) {
        self.notificationName = notificationName
    }

    public var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in
                triggerConfetti()
            }
    }

    private func triggerConfetti() {
        Task { @MainActor in
            await SwiftConfetti.fire()
        }
    }
}
