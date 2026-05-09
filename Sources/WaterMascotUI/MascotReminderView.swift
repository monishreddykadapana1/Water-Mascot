import SwiftUI

public enum ReminderReason {
    case manual
    case scheduled
    case snooze
    case test
}

public struct MascotReminderView: View {
    let message: String
    let celebrationMessage: String
    let celebrationAutoDismissAfter: TimeInterval
    let reason: ReminderReason
    let onDone: () -> Void
    let onSnooze: () -> Void
    @State private var isMascotVisible = false
    @State private var isBubbleVisible = false
    @State private var isExiting = false
    @State private var isCelebrating = false

    public init(
        message: String,
        celebrationMessage: String = "Hydration point secured",
        celebrationAutoDismissAfter: TimeInterval = 3,
        reason: ReminderReason,
        onDone: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        self.message = message
        self.celebrationMessage = celebrationMessage
        self.celebrationAutoDismissAfter = celebrationAutoDismissAfter
        self.reason = reason
        self.onDone = onDone
        self.onSnooze = onSnooze
    }

    public var body: some View {
        VStack(alignment: .center, spacing: -8) {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(isCelebrating ? celebrationMessage : message)
                        .font(.system(size: 12, weight: isCelebrating ? .semibold : .medium))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .lineLimit(isCelebrating ? 2 : 3)
                        .fixedSize(horizontal: false, vertical: true)

                    if !isCelebrating {
                        HStack(spacing: 8) {
                        Button(action: { performExitThen(onSnooze) }) {
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
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(AnimatedButtonStyle())
                        .disabled(isExiting)

                        Button(action: performSuccessSequence) {
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
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(AnimatedButtonStyle())
                        .disabled(isExiting)
                        }
                    }
                }
                .padding(16)
                .frame(width: 320, alignment: .topLeading)
                .background(Color(red: 0.15, green: 0.17, blue: 0.28))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                MessageBubblePolygonTail()
                    .allowsHitTesting(false)
            }
            .padding(.bottom, -14)
            .opacity(isBubbleVisible ? 1 : 0)
            .scaleEffect(isBubbleVisible ? 1 : 0.96, anchor: .bottom)
            .offset(y: isBubbleVisible ? 0 : 10)

            MascotImageView(
                assetName: isCelebrating ? "mascot_celebrate" : "mascot_reminder",
                fallbackSystemImage: isCelebrating ? "checkmark.circle.fill" : "drop.fill"
            )
                .frame(width: 160, height: 160)
                .opacity(isMascotVisible ? 1 : 0)
                .scaleEffect(isMascotVisible ? 1 : 0.96, anchor: .bottom)
                .offset(y: isMascotVisible ? 0 : 8)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(width: 360, height: 340, alignment: .bottom)
        .background(Color.clear)
        .onAppear(perform: runEntranceAnimation)
    }

    private func runEntranceAnimation() {
        isMascotVisible = false
        isBubbleVisible = false
        isExiting = false
        isCelebrating = false

        withAnimation(MascotMotion.easeOut) {
            isMascotVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.bubbleDelay) {
            withAnimation(MascotMotion.easeOut) {
                isBubbleVisible = true
            }
        }
    }

    private func performSuccessSequence() {
        guard !isExiting else {
            return
        }

        isExiting = true

        DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.buttonReboundDelay) {
            withAnimation(MascotMotion.easeOut) {
                isBubbleVisible = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.buttonReboundDelay + MascotMotion.duration) {
            isCelebrating = true
            isExiting = false

            DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.bubbleDelay) {
                withAnimation(MascotMotion.easeOut) {
                    isBubbleVisible = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + MascotMotion.buttonReboundDelay + MascotMotion.duration + MascotMotion.bubbleDelay + celebrationAutoDismissAfter
        ) {
            performExitThen(onDone, waitForButtonRebound: false)
        }
    }

    private func performExitThen(_ action: @escaping () -> Void, waitForButtonRebound: Bool = true) {
        guard !isExiting else {
            return
        }

        isExiting = true
        let initialDelay = waitForButtonRebound ? MascotMotion.buttonReboundDelay : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            withAnimation(MascotMotion.easeOut) {
                isBubbleVisible = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + MascotMotion.bubbleDelay) {
            withAnimation(MascotMotion.easeOut) {
                isMascotVisible = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + MascotMotion.bubbleDelay + MascotMotion.duration) {
            action()
        }
    }
}

public struct MascotCelebrationView: View {
    let message: String
    let autoDismissAfter: TimeInterval?
    let onDismiss: (() -> Void)?
    @State private var isMascotVisible = false
    @State private var isBubbleVisible = false
    @State private var isExiting = false

    public init(
        message: String,
        autoDismissAfter: TimeInterval? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.autoDismissAfter = autoDismissAfter
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .center, spacing: -8) {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(width: 320, alignment: .center)
                .background(Color(red: 0.15, green: 0.17, blue: 0.28))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                MessageBubblePolygonTail()
                    .allowsHitTesting(false)
            }
            .padding(.bottom, -14)
            .opacity(isBubbleVisible ? 1 : 0)
            .scaleEffect(isBubbleVisible ? 1 : 0.96, anchor: .bottom)
            .offset(y: isBubbleVisible ? 0 : 10)

            MascotImageView(assetName: "mascot_celebrate", fallbackSystemImage: "checkmark.circle.fill")
                .frame(width: 160, height: 160)
                .opacity(isMascotVisible ? 1 : 0)
                .scaleEffect(isMascotVisible ? 1 : 0.96, anchor: .bottom)
                .offset(y: isMascotVisible ? 0 : 8)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(width: 360, height: 340, alignment: .bottom)
        .background(Color.clear)
        .onAppear(perform: runEntranceAnimation)
    }

    private func runEntranceAnimation() {
        isMascotVisible = false
        isBubbleVisible = false

        withAnimation(MascotMotion.easeOut) {
            isMascotVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.bubbleDelay) {
            withAnimation(MascotMotion.easeOut) {
                isBubbleVisible = true
            }
        }

        if let autoDismissAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) {
                runExitAnimation()
            }
        }
    }

    private func runExitAnimation() {
        guard !isExiting else {
            return
        }

        isExiting = true

        withAnimation(MascotMotion.easeOut) {
            isBubbleVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.bubbleDelay) {
            withAnimation(MascotMotion.easeOut) {
                isMascotVisible = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + MascotMotion.bubbleDelay + MascotMotion.duration) {
            onDismiss?()
        }
    }
}

private enum MascotMotion {
    static let bubbleDelay: TimeInterval = 0.1
    static let buttonReboundDelay: TimeInterval = 0.15
    static let duration: TimeInterval = 0.2
    static let easeOut = Animation.easeOut(duration: duration)
}

private struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: MascotMotion.buttonReboundDelay), value: configuration.isPressed)
            .onHover { isHovered in
                if isHovered {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
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
            .rotationEffect(.degrees(-95))
            .offset(y: 14)
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

#if DEBUG
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
#endif
