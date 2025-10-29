import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {

    // MARK: - Published state (UI watches this)

    @Published var currentUser: UserProfile?
    @Published var appLanguage: AppLanguage = .english

    // локализованные строки для UI
    var strings: LocalizedStrings {
        LocalizedTextProvider.strings(for: appLanguage)
    }

    // MARK: - storage keys

    private let userKey = "tg_current_user_v1"
    private let langKey = "tg_app_language_v1"

    // MARK: - init

    init() {
        // восстановить язык
        if let raw = UserDefaults.standard.string(forKey: langKey),
           let saved = AppLanguage(rawValue: raw) {
            self.appLanguage = saved
        }

        // восстановить пользователя
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = user
        }
    }

    // MARK: - helpers

    private func persistUser(_ user: UserProfile?) {
        if let user {
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: userKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: userKey)
        }
    }

    func setLanguage(_ lang: AppLanguage) {
        appLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: langKey)
    }

    // MARK: - Auth API
    // Вместо Result мы теперь возвращаем просто опциональную строку ошибки:
    // nil = успех, строка = ошибка.

    func login(email: String, password: String) async -> String? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass  = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty, !cleanPass.isEmpty else {
            return "Email and password are required."
        }

        do {
            let pu = try await Back4AppService.login(
                usernameOrEmail: cleanEmail,
                password: cleanPass
            )

            let profile = UserProfile(
                userId: UUID(),
                parseObjectId: pu.objectId,
                sessionToken: pu.sessionToken,
                name: pu.name ?? (pu.username ?? cleanEmail),
                email: pu.email ?? cleanEmail,
                avatarImageDataBase64: nil
            )

            self.currentUser = profile
            persistUser(profile)

            return nil // успех, без ошибки
        } catch {
            return error.localizedDescription
        }
    }

    func register(name: String, email: String, password: String) async -> String? {
        let cleanName  = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass  = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty, !cleanEmail.isEmpty, !cleanPass.isEmpty else {
            return "Name, email and password are required."
        }

        do {
            let pu = try await Back4AppService.registerUser(
                name: cleanName,
                email: cleanEmail,
                password: cleanPass
            )

            let profile = UserProfile(
                userId: UUID(),
                parseObjectId: pu.objectId,
                sessionToken: pu.sessionToken,
                name: cleanName,
                email: cleanEmail,
                avatarImageDataBase64: nil
            )

            self.currentUser = profile
            persistUser(profile)

            return nil // успех
        } catch {
            return error.localizedDescription
        }
    }

    func logout() {
        currentUser = nil
        persistUser(nil)
    }
}
