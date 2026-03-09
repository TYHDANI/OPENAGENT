import SwiftUI

/// Premium onboarding view — the Onboarding agent will customize this
/// with app-specific content, colors, and copy.
struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var animateContent = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "star.fill",
            title: "Welcome to {{APP_NAME}}",
            description: "{{VALUE_PROP_1 — What makes this app special}}",
            gradient: [Color.blue, Color.purple]
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "{{FEATURE_1_TITLE}}",
            description: "{{FEATURE_1_DESCRIPTION}}",
            gradient: [Color.purple, Color.pink]
        ),
        OnboardingPage(
            icon: "heart.fill",
            title: "{{FEATURE_2_TITLE}}",
            description: "{{FEATURE_2_DESCRIPTION}}",
            gradient: [Color.pink, Color.orange]
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            title: "Ready to Start",
            description: "{{FINAL_CTA — Why they should start now}}",
            gradient: [Color.green, Color.teal]
        )
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.15)
            .ignoresSafeArea()
            .animation(AppAnimation.easeSmooth, value: currentPage)

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .sensoryFeedback(.impact(weight: .light), trigger: currentPage)

                // Custom page indicator
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(AppAnimation.springSnappy, value: currentPage)
                    }
                }
                .padding(.bottom, AppSpacing.lg)

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    if currentPage > 0 {
                        Button {
                            AppHaptics.selection()
                            withAnimation(AppAnimation.springSnappy) { currentPage -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Previous page")
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            AppHaptics.selection()
                            completeOnboarding()
                        }
                        .font(AppTypography.callout)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Skip onboarding")
                    }

                    Button {
                        AppHaptics.impact(.medium)
                        if currentPage == pages.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation(AppAnimation.springSnappy) { currentPage += 1 }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(.white)
                            .frame(minWidth: 140, minHeight: 50)
                            .background(
                                LinearGradient(
                                    colors: pages[currentPage].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: pages[currentPage].gradient.first?.opacity(0.4) ?? .clear, radius: 12, y: 6)
                    }
                    .animation(AppAnimation.easeSmooth, value: currentPage)
                    .accessibilityLabel(currentPage == pages.count - 1 ? "Get started" : "Continue to next page")
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
                .animation(AppAnimation.springSnappy, value: currentPage)
            }
        }
    }

    private func completeOnboarding() {
        AppHaptics.success()
        withAnimation(AppAnimation.easeSmooth) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var animateIcon = false
    @State private var showTitle = false
    @State private var showDescription = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: page.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.variableColor.iterative, options: .repeating, value: animateIcon)
                .scaleEffect(isActive ? 1.0 : 0.8)
                .opacity(isActive ? 1.0 : 0.5)
                .animation(AppAnimation.springBounce, value: isActive)

            VStack(spacing: AppSpacing.sm) {
                Text(page.title)
                    .font(AppTypography.heroTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .offset(y: showTitle ? 0 : 20)
                    .opacity(showTitle ? 1 : 0)

                Text(page.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .offset(y: showDescription ? 0 : 20)
                    .opacity(showDescription ? 1 : 0)
            }

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active {
                showTitle = false
                showDescription = false
                animateIcon = false

                withAnimation(AppAnimation.easeSmooth.delay(0.1)) {
                    animateIcon = true
                }
                withAnimation(AppAnimation.easeSmooth.delay(0.2)) {
                    showTitle = true
                }
                withAnimation(AppAnimation.easeSmooth.delay(0.35)) {
                    showDescription = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppAnimation.easeSmooth) { animateIcon = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(AppAnimation.easeSmooth) { showTitle = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(AppAnimation.easeSmooth) { showDescription = true }
                }
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

#Preview {
    OnboardingView()
}
