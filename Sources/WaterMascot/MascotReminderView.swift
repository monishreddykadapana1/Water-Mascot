import SwiftUI

enum ReminderReason {
    case manual
    case scheduled
    case snooze
    case test
}

struct MascotReminderView: View {
    let message: String
    let reason: ReminderReason
    let onDone: () -> Void
    let onSnooze: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            MascotImageView(assetName: "mascot_reminder", fallbackSystemImage: "drop.fill")
                .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .font(.system(size: 15, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button("Snooze") {
                        onSnooze()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("I drank water") {
                        onDone()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 300, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                SpeechBubbleTail()
                    .fill(.regularMaterial)
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(45))
                    .offset(x: -7, y: -24)
            }
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .frame(width: 510, height: 190)
        .background(Color.clear)
    }
}

struct MascotCelebrationView: View {
    let message: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            MascotImageView(assetName: "mascot_celebrate", fallbackSystemImage: "checkmark.circle.fill")
                .frame(width: 145, height: 145)

            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(width: 275, alignment: .leading)
                .frame(minHeight: 74, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .leading) {
                    SpeechBubbleTail()
                        .fill(.regularMaterial)
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(45))
                        .offset(x: -7)
                }
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                .padding(.bottom, 42)
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .frame(width: 470, height: 180)
        .background(Color.clear)
    }
}

private struct SpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 3, height: 3))
        return path
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
