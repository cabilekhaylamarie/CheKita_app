import SwiftUI

/// Soft aqua wave that sits behind the status bar / header of the main screens.
struct CKTopWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.62))
        path.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.72),
                      control1: CGPoint(x: w * 0.86, y: h * 0.98),
                      control2: CGPoint(x: w * 0.70, y: h * 0.50))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.80),
                      control1: CGPoint(x: w * 0.32, y: h * 0.96),
                      control2: CGPoint(x: w * 0.14, y: h * 0.62))
        path.closeSubpath()
        return path
    }
}

/// Second, lighter wave layered behind the first for depth.
struct CKTopWaveBackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.86))
        path.addCurve(to: CGPoint(x: w * 0.40, y: h * 0.84),
                      control1: CGPoint(x: w * 0.78, y: h * 0.70),
                      control2: CGPoint(x: w * 0.60, y: h * 1.02))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.66),
                      control1: CGPoint(x: w * 0.22, y: h * 0.68),
                      control2: CGPoint(x: w * 0.10, y: h * 0.80))
        path.closeSubpath()
        return path
    }
}

struct CKTopWave: View {
    var height: CGFloat = 120

    var body: some View {
        ZStack(alignment: .top) {
            CKTopWaveBackShape()
                .fill(CKColor.aqua.opacity(0.55))
                .frame(height: height)
            CKTopWaveShape()
                .fill(LinearGradient(colors: [CKColor.aquaStrong.opacity(0.75), CKColor.aqua.opacity(0.65)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: height * 0.82)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Organic blob used on the auth screens.
struct CKBlobShape: Shape {
    /// Control points expressed as fractions of the rect (closed loop, smoothed).
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard points.count > 2 else { return Path() }
        let pts = points.map { CGPoint(x: $0.x * rect.width, y: $0.y * rect.height) }
        var path = Path()
        let count = pts.count
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        path.move(to: mid(pts[count - 1], pts[0]))
        for i in 0..<count {
            let current = pts[i]
            let next = pts[(i + 1) % count]
            path.addQuadCurve(to: mid(current, next), control: current)
        }
        path.closeSubpath()
        return path
    }
}

/// Light aqua blobs framing the Login / Sign Up screens.
struct CKAuthBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Color.white
                // Top-left
                CKBlobShape(points: [CGPoint(x: -0.2, y: -0.1), CGPoint(x: 0.55, y: -0.05), CGPoint(x: 0.42, y: 0.12),
                                     CGPoint(x: 0.18, y: 0.14), CGPoint(x: 0.08, y: 0.26), CGPoint(x: -0.2, y: 0.3)])
                    .fill(CKColor.aqua)
                // Top-right
                CKBlobShape(points: [CGPoint(x: 0.72, y: -0.05), CGPoint(x: 1.2, y: -0.05), CGPoint(x: 1.2, y: 0.36),
                                     CGPoint(x: 0.96, y: 0.30), CGPoint(x: 0.86, y: 0.16), CGPoint(x: 0.70, y: 0.10)])
                    .fill(CKColor.aqua.opacity(0.9))
                // Bottom
                CKBlobShape(points: [CGPoint(x: -0.2, y: 0.78), CGPoint(x: 0.18, y: 0.84), CGPoint(x: 0.52, y: 0.80),
                                     CGPoint(x: 0.86, y: 0.88), CGPoint(x: 1.2, y: 0.80), CGPoint(x: 1.2, y: 1.2),
                                     CGPoint(x: -0.2, y: 1.2)])
                    .fill(CKColor.aqua.opacity(0.85))
                CKBlobShape(points: [CGPoint(x: 0.55, y: 0.93), CGPoint(x: 0.9, y: 0.86), CGPoint(x: 1.2, y: 0.9),
                                     CGPoint(x: 1.2, y: 1.2), CGPoint(x: 0.5, y: 1.2)])
                    .fill(CKColor.aquaStrong.opacity(0.7))
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// White screen with the aqua header wave behind the status bar.
    func ckScreenBackground(waveHeight: CGFloat = 120) -> some View {
        background(alignment: .top) {
            ZStack(alignment: .top) {
                Color.white
                CKTopWave(height: waveHeight)
            }
            .ignoresSafeArea()
        }
    }
}
