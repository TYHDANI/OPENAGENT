import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            NETheme.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "globe",
                    iconColor: NETheme.accent,
                    title: "Welcome to Nighteye",
                    subtitle: "Real-time global intelligence on a 3D interactive globe",
                    features: [
                        ("waveform.path.ecg", "Live earthquake, wildfire & flood tracking"),
                        ("satellite", "Real-time satellite positions from CelesTrak"),
                        ("cloud.sun", "Hyperlocal weather from Open-Meteo"),
                    ]
                )
                .tag(0)

                // Page 2: Data Layers
                OnboardingPage(
                    icon: "square.3.layers.3d",
                    iconColor: NETheme.accentSecondary,
                    title: "30+ Data Layers",
                    subtitle: "Toggle intelligence feeds on your globe",
                    features: [
                        ("flame", "NASA FIRMS fire detection satellites"),
                        ("airplane", "OpenSky aircraft tracking network"),
                        ("play.tv", "Live news & weather TV from 190+ countries"),
                    ]
                )
                .tag(1)

                // Page 3: Smart Money
                OnboardingPage(
                    icon: "banknote",
                    iconColor: Color(hex: "#4CAF50"),
                    title: "Smart Money Tracking",
                    subtitle: "Follow political money before anyone else",
                    features: [
                        ("person.2.fill", "House & Senate politician stock trades"),
                        ("building.columns.fill", "Government contracts & lobbying data"),
                        ("chart.line.uptrend.xyaxis", "Capital flow cascade analysis engine"),
                    ]
                )
                .tag(2)

                // Page 4: Satellite Imagery
                OnboardingPage(
                    icon: "photo.artframe",
                    iconColor: .purple,
                    title: "Maxar Satellite Imagery",
                    subtitle: "High-resolution disaster imagery from space",
                    features: [
                        ("globe.americas", "28 disaster events across 4 satellites"),
                        ("slider.horizontal.below.rectangle", "Before/after comparison views"),
                        ("antenna.radiowaves.left.and.right", "Weather radar overlay from RainViewer"),
                    ]
                )
                .tag(3)

                // Page 5: Get Started
                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(NETheme.severityLow)

                    Text("You're Ready")
                        .font(NETheme.heading(28))
                        .foregroundStyle(NETheme.textPrimary)

                    Text("All data feeds are free and require no API keys.\nRefreshes automatically every 15 minutes.")
                        .font(NETheme.body())
                        .foregroundStyle(NETheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        appState.completeOnboarding()
                    } label: {
                        Text("Launch Nighteye")
                            .font(NETheme.subheading())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(NETheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .interactiveDismissDisabled()
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let features: [(String, String)]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(iconColor)
                .shadow(color: iconColor.opacity(0.4), radius: 20)

            Text(title)
                .font(NETheme.heading(26))
                .foregroundStyle(NETheme.textPrimary)

            Text(subtitle)
                .font(NETheme.body(16))
                .foregroundStyle(NETheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.1) { icon, text in
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(NETheme.accent)
                            .frame(width: 36)
                        Text(text)
                            .font(NETheme.body(14))
                            .foregroundStyle(NETheme.textSecondary)
                    }
                }
            }
            .padding(24)
            .glassCard()
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}
