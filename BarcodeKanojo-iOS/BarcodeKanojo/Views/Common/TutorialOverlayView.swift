import SwiftUI

/// First-time tutorial overlay for the kanojo room.
/// Shows a sequence of step-through cards explaining interaction mechanics.
/// Uses @AppStorage to show only once.
struct TutorialOverlayView: View {
    let onDismiss: () -> Void

    @State private var currentStep = 0

    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "hand.tap.fill",
            title: "Tap to Interact",
            description: "Tap different parts of your kanojo to trigger reactions. Touch the face, body, or head for different animations!",
            color: .pink
        ),
        TutorialStep(
            icon: "hand.tap.fill",
            title: "Double Tap to Pat",
            description: "Double tap on your kanojo to give a head pat. She'll react with a happy expression!",
            color: .orange
        ),
        TutorialStep(
            icon: "iphone.radiowaves.left.and.right",
            title: "Shake for Dizzy",
            description: "Shake your device and watch your kanojo get dizzy! (Don't worry, it's just for fun.)",
            color: .purple
        ),
        TutorialStep(
            icon: "calendar.badge.plus",
            title: "Go on Dates",
            description: "Take your kanojo on dates to increase love. Different date spots give different results!",
            color: .blue
        ),
        TutorialStep(
            icon: "gift.fill",
            title: "Give Gifts",
            description: "Give your kanojo gifts to boost the love gauge. Choose from store items or use ones you already own.",
            color: .green
        )
    ]

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            VStack(spacing: 24) {
                Spacer()

                // Step card
                if currentStep < steps.count {
                    let step = steps[currentStep]

                    VStack(spacing: 16) {
                        // Icon
                        Image(systemName: step.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(step.color)
                            .padding(.top, 8)

                        // Title
                        Text(step.title)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        // Description
                        Text(step.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        // Progress dots
                        HStack(spacing: 8) {
                            ForEach(0..<steps.count, id: \.self) { i in
                                Circle()
                                    .fill(i == currentStep ? step.color : Color.secondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 4)

                        // Buttons
                        HStack(spacing: 16) {
                            // Skip
                            Button("Skip") {
                                onDismiss()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            Spacer()

                            // Next / Done
                            Button {
                                advance()
                            } label: {
                                Text(currentStep == steps.count - 1 ? "Got It!" : "Next")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(step.color, in: Capsule())
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentStep)
                }

                Spacer()
                    .frame(height: 80)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private func advance() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        } else {
            onDismiss()
        }
    }
}

// MARK: - Tutorial Step

private struct TutorialStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
