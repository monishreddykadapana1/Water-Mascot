import SwiftUI

public enum ReminderReason {
    case manual
    case scheduled
    case snooze
    case test
}

public struct MascotReminderView: View {
    let message: String
    let reason: ReminderReason
    let onDone: () -> Void
    let onSnooze: () -> Void

    public init(
        message: String,
        reason: ReminderReason,
        onDone: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        self.message = message
        self.reason = reason
        self.onDone = onDone
        self.onSnooze = onSnooze
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MascotImageView(assetName: "mascot_reminder", fallbackSystemImage: "drop.fill")
                .frame(width: 160, height: 160)

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Button(action: onSnooze) {
                            HStack(alignment: .center, spacing: 10) {
                                Text("Snooze")
                            }
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                            .frame(width: 80, alignment: .center)
                            .background(Color(red: 0.49, green: 0.52, blue: 0.67).opacity(0.1))
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 2)
                                    .padding(.horizontal, 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.cancelAction)

                        Button(action: onDone) {
                            HStack(alignment: .center, spacing: 10) {
                                Text("On it")
                            }
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                            .frame(width: 80, alignment: .center)
                            .background(Color(red: 0.93, green: 0.53, blue: 0.4))
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(height: 2)
                                    .padding(.horizontal, 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(16)
                .frame(width: 320, alignment: .topLeading)
                .background(Color(red: 0.15, green: 0.17, blue: 0.28))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                MessageBubblePolygonTail()
                    .allowsHitTesting(false)
            }
            // Let the tail extend left past the bubble without clipping; it sits in the 12pt mascot gap.
            .padding(.leading, -14)
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .frame(width: 548, height: 190)
        .background(Color.clear)
    }
}

public struct MascotCelebrationView: View {
    let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MascotImageView(assetName: "mascot_celebrate", fallbackSystemImage: "checkmark.circle.fill")
                .frame(width: 160, height: 160)

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color(red: 0.15, green: 0.17, blue: 0.28))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                MessageBubblePolygonTail()
                    .allowsHitTesting(false)
            }
            .padding(.leading, -14)
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .frame(width: 488, height: 180)
        .background(Color.clear)
    }
}

/// Bubble tail from SVG `viewBox="0 0 17 19"` (absolute path commands). Pinned with a fixed frame + offset, not relative layout.
private struct BubbleTailVectorShape: Shape {
    private static let viewBox = CGRect(x: 0, y: 0, width: 17, height: 19)

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 1, y: 11.0981))
        p.addCurve(
            to: CGPoint(x: 1, y: 7.63404),
            control1: CGPoint(x: -0.333333, y: 10.3283),
            control2: CGPoint(x: -0.333333, y: 8.40384)
        )
        p.addLine(to: CGPoint(x: 13.75, y: 0.272823))
        p.addCurve(
            to: CGPoint(x: 16.75, y: 2.00487),
            control1: CGPoint(x: 15.0833, y: -0.496978),
            control2: CGPoint(x: 16.75, y: 0.465272)
        )
        p.addLine(to: CGPoint(x: 16.75, y: 16.7273))
        p.addCurve(
            to: CGPoint(x: 13.75, y: 18.4594),
            control1: CGPoint(x: 16.75, y: 18.2669),
            control2: CGPoint(x: 15.0833, y: 19.2292)
        )
        p.addLine(to: CGPoint(x: 1, y: 11.0981))
        p.closeSubpath()

        let sx = rect.width / Self.viewBox.width
        let sy = rect.height / Self.viewBox.height
        let t = CGAffineTransform(a: sx, b: 0, c: 0, d: sy, tx: rect.minX, ty: rect.minY)
        return p.applying(t)
    }
}

private struct MessageBubblePolygonTail: View {
    /// Matches bubble fill so the join is seamless; shape is visible against the desktop in the mascot gap.
    private static let tailFill = Color(red: 0.15, green: 0.17, blue: 0.28)

    var body: some View {
        BubbleTailVectorShape()
            .fill(Self.tailFill)
            .frame(width: 17, height: 19)
            // Anticlockwise 90° (`rotationEffect`: positive is clockwise, so use -90).
            .rotationEffect(.degrees(-5))
            .offset(x: -10, y: 10)
            .accessibilityHidden(true)
    }
}

private struct MascotImageView: View {
    let assetName: String
    let fallbackSystemImage: String

    var body: some View {
        if let image = loadMascotImage(named: assetName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.14))

                Image(systemName: fallbackSystemImage)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .accessibilityHidden(true)
        }
    }

    private func loadMascotImage(named assetName: String) -> NSImage? {
        let url = Bundle.module.url(forResource: assetName, withExtension: "png")
            ?? Bundle.module.url(
                forResource: assetName,
                withExtension: "png",
                subdirectory: "Mascot"
            )

        guard let url else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

#if DEBUG
struct MascotReminderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MascotReminderView(
                message: "Hydration timeout. One quick sip, then back in the match.",
                reason: .test,
                onDone: {},
                onSnooze: {}
            )
            .previewDisplayName("Reminder")

            MascotCelebrationView(message: "Hydration point secured.")
                .previewDisplayName("Celebration")
        }
        .previewLayout(.sizeThatFits)
        .padding(24)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
#endif

#Preview("Reminder") {
    MascotReminderView(
        message: "Quick water break. Champions hydrate between rallies.",
        reason: .test,
        onDone: {},
        onSnooze: {}
    )
}

#Preview("Celebration") {
    MascotCelebrationView(message: "Hydration point secured.")
}
