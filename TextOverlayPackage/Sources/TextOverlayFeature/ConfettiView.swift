import SwiftUI

struct Confetti: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    let size: CGFloat
    let color: Color
    var angle: Double
    var angleVelocity: Double
    var opacity: Double = 1.0

    init(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat) {
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.size = CGFloat.random(in: 5...15)
        self.angle = Double.random(in: 0...(2 * .pi))
        self.angleVelocity = Double.random(in: -0.2...0.2)

        let colors: [Color] = [
            Color(red: 1.0, green: 0.027, blue: 0.431),
            Color(red: 0.984, green: 0.337, blue: 0.027),
            Color(red: 1.0, green: 0.745, blue: 0.043),
            Color(red: 0.514, green: 0.22, blue: 0.925),
            Color(red: 0.227, green: 0.525, blue: 1.0),
            Color(red: 0.024, green: 1.0, blue: 0.647),
            Color(red: 1.0, green: 0.263, blue: 0.396),
            Color(red: 0, green: 0.733, blue: 0.976),
            Color(red: 0.996, green: 0.906, blue: 0.478),
            Color(red: 0.969, green: 0.145, blue: 0.522),
            Color(red: 0.447, green: 0.035, blue: 0.718),
            Color(red: 0.337, green: 0.043, blue: 0.678)
        ]
        self.color = colors.randomElement()!
    }

    mutating func update(gravity: CGFloat = 0.1, friction: CGFloat = 0.99, screenHeight: CGFloat) {
        x += vx
        y += vy
        vy += gravity
        vx *= friction
        vy *= friction
        angle += angleVelocity

        if y > screenHeight - 100 {
            opacity = max(0, opacity - 0.02)
        }
    }

    var isAlive: Bool {
        return opacity > 0
    }
}

@MainActor
class ConfettiViewModel: ObservableObject {
    @Published var confettiArray: [Confetti] = []
    private var displayLink: Timer?

    func createConfettiExplosion(x: CGFloat, y: CGFloat, direction: CGFloat) {
        let particleCount = 100

        for _ in 0..<particleCount {
            let baseAngle = -Double.pi / 4
            let angleVariation = (Double.random(in: 0...1) - 0.5) * Double.pi / 6
            let angle = baseAngle + angleVariation

            let velocity = CGFloat.random(in: 10...30)
            let vx = CGFloat(cos(angle)) * velocity * direction
            let vy = CGFloat(sin(angle)) * velocity

            let confetti = Confetti(x: x, y: y, vx: vx, vy: vy)
            confettiArray.append(confetti)
        }
    }

    func triggerCrackers(screenWidth: CGFloat, screenHeight: CGFloat) {
        let baseY = screenHeight * 0.75

        createConfettiExplosion(x: 0, y: baseY, direction: 1)
        createConfettiExplosion(x: screenWidth, y: baseY, direction: -1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.createConfettiExplosion(x: 0, y: baseY - 30, direction: 1)
            self?.createConfettiExplosion(x: screenWidth, y: baseY - 30, direction: -1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.createConfettiExplosion(x: 0, y: baseY + 30, direction: 1)
            self?.createConfettiExplosion(x: screenWidth, y: baseY + 30, direction: -1)
        }
    }

    func startAnimation(screenHeight: CGFloat) {
        displayLink?.invalidate()

        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                for index in self.confettiArray.indices {
                    self.confettiArray[index].update(screenHeight: screenHeight)
                }

                self.confettiArray = self.confettiArray.filter { $0.isAlive }

                if self.confettiArray.isEmpty {
                    self.displayLink?.invalidate()
                    self.displayLink = nil
                }
            }
        }
    }

    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

struct ConfettiView: View {
    @StateObject private var viewModel = ConfettiViewModel()
    let screenSize: CGSize

    var body: some View {
        Canvas { context, size in
            for confetti in viewModel.confettiArray {
                context.opacity = confetti.opacity

                var transform = CGAffineTransform(translationX: confetti.x, y: confetti.y)
                transform = transform.rotated(by: CGFloat(confetti.angle))

                let rect = CGRect(
                    x: -confetti.size / 2,
                    y: -confetti.size / 2,
                    width: confetti.size,
                    height: confetti.size * 0.6
                )

                context.withCGContext { cgContext in
                    cgContext.saveGState()
                    cgContext.concatenate(transform)
                    cgContext.setFillColor(NSColor(confetti.color).cgColor)
                    cgContext.fill(rect)
                    cgContext.restoreGState()
                }
            }
        }
        .allowsHitTesting(false)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TriggerConfetti"))) { _ in
            viewModel.triggerCrackers(screenWidth: screenSize.width, screenHeight: screenSize.height)
            viewModel.startAnimation(screenHeight: screenSize.height)
        }
        .onDisappear {
            viewModel.stopAnimation()
        }
    }
}