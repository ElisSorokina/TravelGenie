import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorText: String?
    @State private var isLoading = false

    @State private var goToRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // Заголовок
                VStack(spacing: 6) {
                    Text("TravelGenie")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppTheme.accent)

                    Text("Log in")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Access your saved trips, checklists and chat history 💗")
                        .font(.footnote)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Поля ввода
                VStack(spacing: 16) {

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

                        SecureField("your password", text: $password)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)

                // Ошибка
                if let errorText {
                    Text(errorText)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Кнопка логина
                Button {
                    Task {
                        await handleLogin()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Log in")
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

                // Перейти на регистрацию
                Button {
                    goToRegister = true
                } label: {
                    Text("No account? Sign up")
                        .font(.footnote)
                        .foregroundColor(AppTheme.accent)
                }

                Spacer(minLength: 0)

                // Навигация к регистрации
                NavigationLink("", isActive: $goToRegister) {
                    RegisterView()
                }
                .hidden()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.bgSoft.ignoresSafeArea())
        }
    }

    // MARK: - login logic
    private func handleLogin() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass  = password.trimmingCharacters(in: .whitespacesAndNewlines)

        let maybeError = await appVM.login(email: cleanEmail, password: cleanPass)

        if let maybeError {
            // не удалось залогиниться
            errorText = maybeError
        } else {
            // успех — appVM.currentUser заполнен
            // AuthGateView автоматически переключится на MainTabView
        }
    }
}
