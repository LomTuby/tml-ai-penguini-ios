import SwiftUI

enum PenguinExpression {
    case idle, happy, thinking, surprised, confused, speaking
}

struct PenguinFace: View {
    let expression: PenguinExpression
    @State private var blink = false
    @State private var wiggle = false
    @State private var mouthOpen = 0.0
    @State private var eyebrowOffset = 0.0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Main Body
                Ellipse()
                    .fill(Color.black)
                    .frame(width: 200, height: 240)

                // White Belly/Face
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 160, height: 200)
                    .offset(y: 10)

                // Eyes & Brows
                HStack(spacing: 40) {
                    VStack(spacing: 5) {
                        Eyebrow(expression: expression)
                        EyeView(isBlinking: blink, expression: expression)
                    }
                    VStack(spacing: 5) {
                        Eyebrow(expression: expression)
                        EyeView(isBlinking: blink, expression: expression)
                    }
                }
                .offset(y: -30)

                // Beak
                BeakView(expression: expression, mouthOpen: mouthOpen)
                    .offset(y: 15)
            }
            .scaleEffect(wiggle ? 1.02 : 1.0)
            .rotationEffect(.degrees(wiggle ? 2 : -2))
        }
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: expression) { _, newExpression in
            handleExpressionChange(newExpression)
        }
    }

    private func startIdleAnimations() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                blink = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    blink = false
                }
            }
        }

        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            wiggle = true
        }
    }

    private func handleExpressionChange(_ expression: PenguinExpression) {
        if expression == .speaking {
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                mouthOpen = 1.0
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                mouthOpen = 0.0
            }
        }
    }
}

struct Eyebrow: View {
    let expression: PenguinExpression

    var body: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: 20, height: 4)
            .rotationEffect(.degrees(eyebrowRotation))
            .offset(y: eyebrowOffset)
    }

    private var eyebrowRotation: Double {
        switch expression {
        case .surprised: return -20
        case .confused: return 20
        case .thinking: return -10
        default: return 0
        }
    }

    private var eyebrowOffset: Double {
        switch expression {
        case .surprised: return -10
        case .thinking: return -5
        default: return 0
        }
    }
}

struct EyeView: View {
    let isBlinking: Bool
    let expression: PenguinExpression

    var body: some View {
        ZStack {
            if isBlinking && expression != .surprised {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 25, height: 4)
            } else {
                Circle()
                    .fill(Color.black)
                    .frame(width: 25, height: 25)
                    .scaleEffect(expression == .surprised ? 1.2 : 1.0)

                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(x: -5, y: -5)

                if expression == .happy {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .offset(y: 15)
                        .mask(Circle().frame(width: 25, height: 25))
                }
            }
        }
    }
}

struct BeakView: View {
    let expression: PenguinExpression
    let mouthOpen: Double

    var body: some View {
        VStack(spacing: -2) {
            Triangle()
                .fill(Color.orange)
                .frame(width: 45, height: 30)

            Triangle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 35, height: 20)
                .rotationEffect(.degrees(180))
                .offset(y: CGFloat(mouthOpen * 12))
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
