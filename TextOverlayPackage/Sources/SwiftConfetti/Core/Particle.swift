import Foundation
import AppKit

/// canvas-confettiのパーティクル構造を完全移植
@MainActor
public class Particle {
    // 一意識別子
    private static var nextId: Int = 0
    public let id: Int

    // 位置と速度
    public var x: Double
    public var y: Double
    public var velocity: Double
    public var angle2D: Double

    // Wobble効果（揺れ）
    public var wobble: Double
    public var wobbleSpeed: Double
    public var wobbleX: Double
    public var wobbleY: Double

    // Tilt効果（傾き）
    public var tiltAngle: Double
    public var tiltSin: Double
    public var tiltCos: Double

    // 物理パラメータ
    public var gravity: Double
    public var drift: Double
    public var decay: Double

    // 外観
    public var color: RGB
    public var shape: ConfettiShape
    public var scalar: Double
    public var ovalScalar: Double

    // アニメーション制御
    public var tick: Int
    public var totalTicks: Int

    // その他
    public var random: Double
    public var flat: Bool

    public init(
        x: Double,
        y: Double,
        angle: Double,
        spread: Double,
        startVelocity: Double,
        color: RGB,
        shape: ConfettiShape,
        ticks: Int,
        decay: Double,
        gravity: Double,
        drift: Double,
        scalar: Double,
        flat: Bool
    ) {
        // 一意のIDを割り当て
        self.id = Particle.nextId
        Particle.nextId += 1

        // canvas-confettiのrandomPhysics関数と同じロジック
        let radAngle = angle * (Double.pi / 180)
        let radSpread = spread * (Double.pi / 180)

        self.x = x
        self.y = y
        self.wobble = Double.random(in: 0..<10)
        self.wobbleSpeed = min(0.11, Double.random(in: 0..<0.1) + 0.05)
        self.velocity = (startVelocity * 0.5) + (Double.random(in: 0..<1) * startVelocity)
        self.angle2D = -radAngle + ((0.5 * radSpread) - (Double.random(in: 0..<1) * radSpread))
        self.tiltAngle = (Double.random(in: 0.25..<0.75)) * Double.pi
        self.color = color
        self.shape = shape
        self.tick = 0
        self.totalTicks = ticks
        self.decay = decay
        self.drift = drift
        self.random = Double.random(in: 0..<1) + 2
        self.tiltSin = 0
        self.tiltCos = 0
        self.wobbleX = 0
        self.wobbleY = 0
        self.gravity = gravity * 3
        self.ovalScalar = 0.6
        self.scalar = scalar
        self.flat = flat
    }
}

/// canvas-confettiのupdateFetti関数を完全移植
@MainActor
public func updateParticle(_ particle: Particle) -> Bool {
    // 位置更新（canvas-confettiと同一ロジック）
    particle.x += cos(particle.angle2D) * particle.velocity + particle.drift
    particle.y += sin(particle.angle2D) * particle.velocity + particle.gravity
    particle.velocity *= particle.decay

    if particle.flat {
        // フラットモード（3D効果なし）
        particle.wobble = 0
        particle.wobbleX = particle.x + (10 * particle.scalar)
        particle.wobbleY = particle.y + (10 * particle.scalar)
        particle.tiltSin = 0
        particle.tiltCos = 0
        particle.random = 1
    } else {
        // 3D効果あり
        particle.wobble += particle.wobbleSpeed
        particle.wobbleX = particle.x + ((10 * particle.scalar) * cos(particle.wobble))
        particle.wobbleY = particle.y + ((10 * particle.scalar) * sin(particle.wobble))

        particle.tiltAngle += 0.1
        particle.tiltSin = sin(particle.tiltAngle)
        particle.tiltCos = cos(particle.tiltAngle)
        particle.random = Double.random(in: 0..<1) + 2
    }

    particle.tick += 1

    // アニメーション継続判定
    return particle.tick < particle.totalTicks
}

/// 描画用の計算値を提供
public extension Particle {
    var progress: Double {
        return Double(tick) / Double(totalTicks)
    }

    var opacity: Double {
        return 1 - progress
    }

    var x1: Double {
        return x + (random * tiltCos)
    }

    var y1: Double {
        return y + (random * tiltSin)
    }

    var x2: Double {
        return wobbleX + (random * tiltCos)
    }

    var y2: Double {
        return wobbleY + (random * tiltSin)
    }

    var width: Double {
        return abs(x2 - x1) * ovalScalar
    }

    var height: Double {
        return abs(y2 - y1) * ovalScalar
    }

    var rotation: Double {
        return (Double.pi / 10) * wobble
    }
}

/// ユーティリティ関数
public func randomInt(min: Int, max: Int) -> Int {
    // canvas-confettiのrandomInt関数と同じ [min, max)
    return Int.random(in: min..<max)
}

public func onlyPositiveInt(_ number: Int) -> Int {
    return number < 0 ? 0 : number
}