import Foundation

enum TripAPIService {

    struct OpenAIChoiceMessage: Decodable {
        let role: String
        let content: String
    }

    struct OpenAIChoice: Decodable {
        let message: OpenAIChoiceMessage
    }

    struct OpenAIResponse: Decodable {
        let choices: [OpenAIChoice]
    }

    // Это наша главная функция. Её вызывает TripViewModel.generateTrip(...)
    static func generateTrip(
        destination: String,
        startDate: Date,
        endDate: Date,
        departureCity: String,
        user: UserProfile?
    ) async throws -> Trip {

        // 1. Собираем промпт для модели (на английском, чтобы лучше работало)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startStr = dateFormatter.string(from: startDate)
        let endStr   = dateFormatter.string(from: endDate)

        let userName = user?.name ?? "Traveler"

        // просим модель вернуть структуру понятного JSON
        // (упрощённо, без фантазийных ключей)
        let systemPrompt =
        """
        You are a travel planning assistant. You produce trip plans in structured JSON.

        Respond ONLY with valid JSON. Do not include any commentary or markdown.

        JSON format:
        {
          "destination": String,
          "flight": {
            "title": String,
            "price": String,
            "url": String
          },
          "hotel": {
            "title": String,
            "price": String,
            "url": String
          },
          "checklist": [
            {
              "title": String,
              "notes": String
            }
          ],
          "mustSee": [
            {
              "title": String,
              "notes": String
            }
          ],
          "days": [
            {
              "label": String,
              "morning": String,
              "afternoon": String,
              "evening": String
            }
          ]
        }
        """

        let userPrompt =
        """
        Plan a trip for \(userName).
        Origin: \(departureCity)
        Destination: \(destination)
        Dates: \(startStr) to \(endStr)

        Include:
        - flight suggestion (airline or site + rough price + link or site)
        - hotel suggestion (hotel name or area + rough price/night + link or site)
        - a pre-trip checklist (buy tickets, book hotel, etc.)
        - must-see places list
        - day-by-day plan morning/afternoon/evening between \(startStr) and \(endStr)

        IMPORTANT: respond with pure JSON exactly in the format described above.
        """

        // 2. Готовим тело запроса к OpenAI Chat Completions
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0.7,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ]
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        // 3. HTTP запрос
        var req = URLRequest(url: Secrets.openAIBaseURL.appendingPathComponent("chat/completions"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = bodyData

        let (respData, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw TripError.network("No HTTPURLResponse")
        }

        guard (200..<300).contains(http.statusCode) else {
            let raw = String(data: respData, encoding: .utf8) ?? "?"
            throw TripError.badStatus(http.statusCode, raw)
        }

        // 4. Парсим openAI ответ
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: respData)

        guard let rawText = decoded.choices.first?.message.content,
              !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TripError.emptyAIResponse
        }

        // 5. rawText должно быть чистым JSON → пробуем декоднуть его в промежуточную структуру
        struct TripJSON: Decodable {
            struct FlightJSON: Decodable {
                let title: String
                let price: String
                let url: String
            }
            struct HotelJSON: Decodable {
                let title: String
                let price: String
                let url: String
            }
            struct ItemJSON: Decodable {
                let title: String
                let notes: String?
            }
            struct DayJSON: Decodable {
                let label: String
                let morning: String
                let afternoon: String
                let evening: String
            }

            let destination: String
            let flight: FlightJSON
            let hotel: HotelJSON
            let checklist: [ItemJSON]
            let mustSee: [ItemJSON]
            let days: [DayJSON]
        }

        guard let tripData = rawText.data(using: .utf8) else {
            throw TripError.jsonDecode("AI returned non-UTF8")
        }

        let parsed: TripJSON
        do {
            parsed = try JSONDecoder().decode(TripJSON.self, from: tripData)
        } catch {
            throw TripError.jsonDecode("Failed to decode AI JSON: \(error)")
        }

        // 6. Превращаем TripJSON в нашу модель Trip

        let flightSuggestion = BookingSuggestion(
            id: UUID(),
            title: parsed.flight.title,
            priceEstimate: parsed.flight.price,
            url: parsed.flight.url
        )

        let hotelSuggestion = BookingSuggestion(
            id: UUID(),
            title: parsed.hotel.title,
            priceEstimate: parsed.hotel.price,
            url: parsed.hotel.url
        )

        let checklistItems: [ChecklistItem] = parsed.checklist.map { item in
            ChecklistItem(
                id: UUID(),
                title: item.title,
                notes: item.notes,
                link: nil,
                isDone: false,
                type: .preTrip
            )
        }

        let mustSeeItems: [ChecklistItem] = parsed.mustSee.map { item in
            ChecklistItem(
                id: UUID(),
                title: item.title,
                notes: item.notes,
                link: nil,
                isDone: false,
                type: .inTrip
            )
        }

        let dayPlans: [DayPlan] = parsed.days.map { d in
            DayPlan(
                id: UUID(),
                dateLabel: d.label,
                morning: d.morning,
                afternoon: d.afternoon,
                evening: d.evening
            )
        }

        let trip = Trip(
            id: UUID(),
            destination: parsed.destination,
            startDate: startDate,
            endDate: endDate,
            flightInfo: flightSuggestion,
            hotelInfo: hotelSuggestion,
            checklist: checklistItems,
            mustSeeList: mustSeeItems,
            dayByDayPlan: dayPlans,
            remoteObjectId: nil
        )

        return trip
    }
}

// ошибки генерации путешествия
enum TripError: LocalizedError {
    case network(String)
    case badStatus(Int, String)
    case emptyAIResponse
    case jsonDecode(String)

    var errorDescription: String? {
        switch self {
        case .network(let msg): return "Network error: \(msg)"
        case .badStatus(let code, let body): return "Server error \(code): \(body)"
        case .emptyAIResponse: return "Empty AI response"
        case .jsonDecode(let msg): return "AI JSON parse failed: \(msg)"
        }
    }
}
