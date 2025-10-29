import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {

    // Все сообщения чата (история)
    @Published var messages: [ChatMessageModel] = []

    // То, что юзер сейчас набирает
    @Published var draft: String = ""

    // Показываем ли "модель думает..."
    @Published var isSending: Bool = false

    // Ошибка (если API упало)
    @Published var errorText: String?

    // Ключ для сохранения истории
    private let historyKey = "chatHistoryMessages_v1"

    init() {
        loadHistory()

        // Если чата нет — добавим приветственное сообщение ассистента
        if messages.isEmpty {
            let welcome = ChatMessageModel(
                sender: .assistant,
                text: "Привет 👋 Я помогу спланировать твою поездку: билеты, отели, маршрут по дням. Скажи, откуда ты летишь и куда хочешь?",
                timestamp: Date()
            )
            messages.append(welcome)
            saveHistory()
        }
    }

    // MARK: - Отправка текущей реплики пользователя
    func sendCurrentDraft() {
        let userText = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        draft = ""
        errorText = nil

        // добавляем сообщение пользователя в ленту
        let userMsg = ChatMessageModel(sender: .user, text: userText)
        messages.append(userMsg)
        saveHistory()

        // просим ответ у модели
        Task {
            await sendToOpenAI(userText: userText)
        }
    }

    // MARK: - Запрос к OpenAI
    private func sendToOpenAI(userText: String) async {
        isSending = true
        defer { isSending = false }

        do {
            // Берём последние до ~10 сообщений, чтобы не раздувать контекст
            let recent = Array(messages.suffix(10))

            // Форматируем историю для Chat Completions API
            // ["role": "user"/"assistant", "content": "..."]
            let openAIMessages: [[String: String]] = recent.map { msg in
                [
                    "role": (msg.sender == .user ? "user" : "assistant"),
                    "content": msg.text
                ]
            }

            // Собираем тело запроса для OpenAI
            let requestBody: [String: Any] = [
                "model": "gpt-4o-mini",
                "temperature": 0.7,
                "messages": openAIMessages
            ]

            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            // Готовим запрос
            var req = URLRequest(url: Secrets.openAIBaseURL.appendingPathComponent("chat/completions"))
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")
            req.httpBody = bodyData

            // Выполняем сетевой запрос
            let (respData, resp) = try await URLSession.shared.data(for: req)

            guard let http = resp as? HTTPURLResponse else {
                throw ChatError.network
            }

            guard (200..<300).contains(http.statusCode) else {
                let errText = String(data: respData, encoding: .utf8) ?? "Unknown OpenAI error"
                print("❌ OpenAI HTTP error:", errText)
                throw ChatError.badStatus(http.statusCode)
            }

            // Парсим ответ OpenAI формата:
            // {
            //   "choices": [
            //     {
            //       "message": {
            //         "role": "assistant",
            //         "content": "ответ текста"
            //       }
            //     }
            //   ]
            // }
            struct ChoiceMessage: Decodable {
                let role: String
                let content: String
            }
            struct Choice: Decodable {
                let message: ChoiceMessage
            }
            struct CompletionResponse: Decodable {
                let choices: [Choice]
            }

            let decoded = try JSONDecoder().decode(CompletionResponse.self, from: respData)

            guard
                let botText = decoded.choices.first?.message.content,
                !botText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                throw ChatError.emptyResult
            }

            // добавляем ответ ассистента
            let botMsg = ChatMessageModel(sender: .assistant, text: botText)
            messages.append(botMsg)
            saveHistory()

        } catch {
            print("❌ Chat error:", error)
            errorText = "Sorry, I couldn't reply."
        }
    }

    // MARK: - сохранение локально
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("❌ Failed to save chat history:", error)
        }
    }

    // MARK: - загрузка локально
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        if let arr = try? JSONDecoder().decode([ChatMessageModel].self, from: data) {
            self.messages = arr
        }
    }
}

// ошибки чата (внутренние)
enum ChatError: Error {
    case network
    case badStatus(Int)
    case emptyResult
}
