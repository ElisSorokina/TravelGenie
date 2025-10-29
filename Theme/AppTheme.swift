import SwiftUI

enum AppTheme {
    // основной акцент — кнопки, активные элементы
    static let accent = Color(red: 1.0, green: 0.62, blue: 0.81) // ~FF9FCF

    // фон всей аппки
    static let bgSoft = Color(red: 1.0, green: 0.97, blue: 0.98) // ~FFF7FB

    // фон карточек / панелей
    static let surface = Color.white

    // текст
    static let textPrimary = Color(red: 0.18, green: 0.18, blue: 0.18)   // #2E2E2E
    static let textSecondary = Color(red: 0.48, green: 0.48, blue: 0.48) // #7B7B7B

    // чаты
    static let bubbleUser = Color(red: 1.0, green: 0.55, blue: 0.78) // более насыщенный розовый
    static let bubbleAssistant = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.9)

    // обводка/тень для карточек
    static let cardShadow = Color.black.opacity(0.07)
}
