import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showBiometricOption = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo / Branding
                VStack(spacing: 12) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)

                    Text("DentiMatch AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Dental Practice Management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .accessibilityLabel("Email address")

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .accessibilityLabel("Password")
                }
                .padding(.horizontal)

                // Sign In Button
                VStack(spacing: 12) {
                    Button {
                        signIn()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(canSignIn ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canSignIn || isLoading)
                    .padding(.horizontal)

                    // Biometric Login
                    if showBiometricOption {
                        Button {
                            biometricSignIn()
                        } label: {
                            Label("Sign in with Face ID", systemImage: "faceid")
                                .font(.subheadline)
                        }
                    }
                }

                Spacer()

                // HIPAA Notice
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)

                    Text("HIPAA Compliant")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("All data is encrypted and stored securely")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom)
            }
            .alert("Sign In Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                checkBiometricAvailability()
            }
        }
    }

    // MARK: - Helpers

    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try await authManager.login(email: email, password: password)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func biometricSignIn() {
        Task {
            do {
                try await authManager.authenticateWithBiometrics()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        showBiometricOption = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
