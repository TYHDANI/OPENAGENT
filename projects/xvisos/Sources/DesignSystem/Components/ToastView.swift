import SwiftUI

enum ToastStyle {
    case success, error, warning, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return AppColors.success
        case .error: return AppColors.error
        case .warning: return AppColors.warning
        case .info: return AppColors.info
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let style: ToastStyle

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToastOverlay: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: toast.style.icon)
                        .foregroundColor(toast.style.color)
                    Text(toast.text)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .appShadow(AppShadow.md)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    AppHaptics.impact(.light)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(AppAnimation.easeSmooth) {
                            self.toast = nil
                        }
                    }
                }
                .onTapGesture {
                    withAnimation(AppAnimation.easeSmooth) {
                        self.toast = nil
                    }
                }
            }
        }
        .animation(AppAnimation.springBounce, value: toast)
    }
}

extension View {
    func toast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(ToastOverlay(toast: message))
    }
}
