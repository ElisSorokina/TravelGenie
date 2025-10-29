//
//  UserProfile.swift
//  TravelGenie
//
//  Created by Elizaveta Sorokina on 10/28/25.
//


import Foundation
import SwiftUI

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    var id: UUID { userId }
    let userId: UUID
    let parseObjectId: String?
    let sessionToken: String?
    let name: String
    let email: String
    var avatarImageDataBase64: String?

    var avatarImage: Image? {
        guard let base64 = avatarImageDataBase64,
              let data = Data(base64Encoded: base64),
              let uiImg = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImg)
    }
}

// MARK: - Trip

struct Trip: Codable, Identifiable {
    let id: UUID
    var destination: String
    var startDate: Date
    var endDate: Date
    var flightInfo: BookingSuggestion?
    var hotelInfo: BookingSuggestion?
    var checklist: [ChecklistItem]
    var mustSeeList: [ChecklistItem]
    var dayByDayPlan: [DayPlan]
    var remoteObjectId: String?

    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

// MARK: - Booking Suggestion (Flight / Hotel)

struct BookingSuggestion: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var priceEstimate: String
    var url: String
}

// MARK: - Checklist Items

enum ChecklistItemType: String, Codable {
    case preTrip
    case inTrip
}

struct ChecklistItem: Codable, Identifiable {
    let id: UUID
    var title: String
    var notes: String?
    var link: String?
    var isDone: Bool
    var type: ChecklistItemType
}

// MARK: - Day-by-Day Plan

struct DayPlan: Codable, Identifiable {
    var id = UUID()
    var dateLabel: String
    var morning: String
    var afternoon: String
    var evening: String
}

// MARK: - Which list are we editing (pre-trip checklist vs must-see list)

enum ListTarget: String, Codable {
    case checklist   // tasks before the trip
    case mustSee     // must-visit places
}

// MARK: - AppLanguage

enum AppLanguage: String, Codable, CaseIterable {
    case english = "en"
    case russian = "ru"
}

// MARK: - LocalizedStrings
// This struct must include EVERY string any view tries to access.
// If a view asks for something that's not here -> compile error.

struct LocalizedStrings {

    // Tab bar
    var tabPlan: String            // "Plan" / "План"
    var tabMyTrip: String          // "My Trips" / "Мои поездки"
    var tabChat: String            // "Chat" / "Чат"
    var tabProfile: String         // "Profile" / "Профиль"

    // PlanTripView
    var screenPlanTitle: String
    var screenPlanSubtitle: String
    var fieldFrom: String
    var fieldTo: String
    var fieldDates: String
    var fieldStart: String
    var fieldEnd: String
    var buttonGenerateTrip: String
    var generatingTrip: String
    var generatingOverlayText: String
    var previewTitle: String

    // "no trips / no active trip" messages
    var noTripYet: String          // e.g. "No trips yet — generate your first one!"
    var noTripsYet: String         // e.g. "No trips yet"

    // MyTripView sections
    var yourTripsTitle: String     // "Your Trips"
    var preTripChecklist: String   // "Before the Trip"
    var mustSeeTitle: String       // "Must See"
    var selectTripPrompt: String   // "Select a trip..."

    // Add item sheet
    var addNewItemTitle: String            // "Add New Item"
    var addNewItemPlaceholder: String      // "What do you want to add?"
    var addNewNotesPlaceholder: String     // "Additional notes (optional)"

    // we also need these for AddItemSheet in new MyTripView
    var addItemTitle: String               // "Add item"
    var fieldTitle: String                 // "Title"
    var fieldNotesOptional: String         // "Notes (optional)"

    // common buttons
    var cancel: String
    var add: String
    var deleteConfirm: String
    var delete: String

    // Chat
    var chatPlaceholder: String    // "Ask about your trip..."
    var chatHello: String          // assistant greeting

    // Profile / settings
    var languageTitle: String          // old (screen header)
    var languagePickerLabel: String    // "App Language"
    var logoutButton: String           // "Log Out"

    // for ProfileView code that expects these names:
    var languageLabel: String { languagePickerLabel }
    var logout: String { logoutButton }
}

// MARK: - LocalizedTextProvider
// Returns the proper LocalizedStrings for RU/EN.
// If you add a new string to LocalizedStrings, add values for both languages here.

enum LocalizedTextProvider {
    static func strings(for lang: AppLanguage) -> LocalizedStrings {
        switch lang {

        case .english:
            return LocalizedStrings(
                tabPlan: "Plan",
                tabMyTrip: "My Trips",
                tabChat: "Chat",
                tabProfile: "Profile",

                screenPlanTitle: "Plan your next adventure",
                screenPlanSubtitle: "Select where you're going and let the AI build your trip plan!",
                fieldFrom: "From",
                fieldTo: "To",
                fieldDates: "Dates",
                fieldStart: "Start Date",
                fieldEnd: "End Date",
                buttonGenerateTrip: "Generate Trip",
                generatingTrip: "Generating...",
                generatingOverlayText: "Building your trip...",
                previewTitle: "Trip Preview",

                noTripYet: "No trips yet — generate your first one!",
                noTripsYet: "No trips yet",

                yourTripsTitle: "Your Trips",
                preTripChecklist: "Before the Trip",
                mustSeeTitle: "Must See",
                selectTripPrompt: "Select a trip to view its details.",

                addNewItemTitle: "Add New Item",
                addNewItemPlaceholder: "What do you want to add?",
                addNewNotesPlaceholder: "Additional notes (optional)",

                addItemTitle: "Add item",
                fieldTitle: "Title",
                fieldNotesOptional: "Notes (optional)",

                cancel: "Cancel",
                add: "Add",
                deleteConfirm: "Delete this trip?",
                delete: "Delete",

                chatPlaceholder: "Ask about your trip...",
                chatHello: "Hi 👋 I'm your travel assistant. I can help with flights, hotels, and a day-by-day plan. Where are you flying from and where do you want to go? ✈️",

                languageTitle: "Language",
                languagePickerLabel: "App Language",
                logoutButton: "Log Out"
            )

        case .russian:
            return LocalizedStrings(
                tabPlan: "План",
                tabMyTrip: "Мои поездки",
                tabChat: "Чат",
                tabProfile: "Профиль",

                screenPlanTitle: "Спланируй путешествие",
                screenPlanSubtitle: "Выбери направление — и ИИ построит план поездки!",
                fieldFrom: "Откуда",
                fieldTo: "Куда",
                fieldDates: "Даты",
                fieldStart: "Дата выезда",
                fieldEnd: "Дата возвращения",
                buttonGenerateTrip: "Создать поездку",
                generatingTrip: "Создание...",
                generatingOverlayText: "ИИ составляет твой маршрут...",
                previewTitle: "Предпросмотр поездки",

                noTripYet: "У тебя пока нет поездок — создай первую!",
                noTripsYet: "Пока нет поездок",

                yourTripsTitle: "Твои поездки",
                preTripChecklist: "Перед поездкой",
                mustSeeTitle: "Места для посещения",
                selectTripPrompt: "Выбери поездку, чтобы увидеть детали.",

                addNewItemTitle: "Добавить пункт",
                addNewItemPlaceholder: "Что добавить?",
                addNewNotesPlaceholder: "Дополнительные заметки (опционально)",

                addItemTitle: "Добавить пункт",
                fieldTitle: "Название",
                fieldNotesOptional: "Заметки (необязательно)",

                cancel: "Отмена",
                add: "Добавить",
                deleteConfirm: "Удалить поездку?",
                delete: "Удалить",

                chatPlaceholder: "Спроси о поездке...",
                chatHello: "Привет 👋 Я помогу спланировать твою поездку: билеты, отели и план по дням. Откуда вылетаешь и куда хочешь? ✈️",

                languageTitle: "Язык интерфейса",
                languagePickerLabel: "Язык приложения",
                logoutButton: "Выйти"
            )
        }
    }
}
