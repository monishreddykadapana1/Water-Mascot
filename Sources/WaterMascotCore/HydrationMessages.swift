import Foundation

public struct HydrationMessages {
    private let reminders = [
        "Hydration timeout. One quick sip, then back in the match",
        "Your water bottle is on the bench waiting to be subbed in",
        "Tiny sip. Big comeback",
        "Coach says: drink water before your brain starts missing receives",
        "Quick water break. Champions hydrate between rallies",
        "Set point for hydration. Don't overthink it",
        "Your focus needs a refill",
        "One sip now. Future you gets the assist",
        "Water check. No dramatic monologue required",
        "A clean receive starts with not being dehydrated"
    ]

    private let celebrations = [
        "🥳 Clean receive",
        "💧 Hydration point secured",
        "💪 Tiny habit, strong rally"
    ]

    public init() {}

    public func randomReminder() -> String {
        reminders.randomElement() ?? reminders[0]
    }

    public func randomCelebration() -> String {
        celebrations.randomElement() ?? celebrations[0]
    }
}
