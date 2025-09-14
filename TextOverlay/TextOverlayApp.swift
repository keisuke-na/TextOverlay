import SwiftUI
import TextOverlayFeature
import AppKit

@main
struct TextOverlayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .stationary]
                window.ignoresMouseEvents = true
                window.hasShadow = false
                window.styleMask = [.borderless]
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden

                // 画面全体をカバーするウィンドウを配置
                if let screen = NSScreen.main {
                    window.setFrame(screen.frame, display: true)
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
