import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 24) {

            VStack(spacing: 6) {
                Text("TravelGenie")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppTheme.accent)

                Text("Create account")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("We'll sync your trips and checklists in the cloud ✨")
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    TextField("you@email.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    SecureField("min 6 characters", text: $password)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 20)

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Button {
                Task {
                    await handleRegister()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Sign up")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isLoading)
            .padding(.horizontal, 20)

            Button {
                dismiss()
            } label: {
                Text("Already have an account? Log in")
                    .font(.footnote)
                    .foregroundColor(AppTheme.accent)
            }
            .padding(.bottom, 40)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bgSoft.ignoresSafeArea())
    }

    private func handleRegister() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }

        let cleanName  = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass  = password.trimmingCharacters(in: .whitespacesAndNewlines)

        let maybeError = await appVM.register(
            name: cleanName,
            email: cleanEmail,
            password: cleanPass
        )

        if let maybeError {
            errorText = maybeError
        } else {
            // регистрация успешна → пользователь создан
            // appVM.currentUser заполнен → AuthGateView покажет MainTabView
            dismiss()
        }
    }
}
