import SwiftUI

/// Template onboarding view — the Onboarding agent will customize this
/// with app-specific content, colors, and copy.
struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "star.fill",
            title: "Welcome to {{APP_NAME}}",
            description: "{{VALUE_PROP_1 — What makes this app special}}",
            color: .blue
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "{{FEATURE_1_TITLE}}",
            description: "{{FEATURE_1_DESCRIPTION}}",
            color: .purple
        ),
        OnboardingPage(
            icon: "heart.fill",
            title: "{{FEATURE_2_TITLE}}",
            description: "{{FEATURE_2_DESCRIPTION}}",
            color: .pink
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            title: "Ready to Start",
            description: "{{FINAL_CTA — Why they should start now}}",
            color: .green
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(page.color)
                            .symbolEffect(.bounce, value: currentPage)

                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(page.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)

            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundStyle(.secondary)
                }

                Button(currentPage == pages.count - 1 ? "Get Started" : "Continue") {
                    if currentPage == pages.count - 1 {
                        completeOnboarding()
                    } else {
                        withAnimation { currentPage += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView()
}
