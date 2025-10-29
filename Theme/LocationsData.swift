import Foundation

// Simple model
struct Country: Identifiable, Hashable {
    var id: String { code }
    let code: String      // "US"
    let name: String      // "United States"
    let cities: [String]  // ["New York", "Los Angeles", "Miami"]
}

// You can expand this list later.
// For now I'm giving a starter set so the UI compiles and works.
// You can add whatever countries/cities you care about.

enum LocationsData {
    static let countries: [Country] = [
        Country(
            code: "US",
            name: "United States",
            cities: ["New York", "Los Angeles", "Miami", "San Francisco", "Chicago", "Austin", "Seattle"]
        ),
        Country(
            code: "CA",
            name: "Canada",
            cities: ["Toronto", "Vancouver", "Montreal", "Calgary"]
        ),
        Country(
            code: "GB",
            name: "United Kingdom",
            cities: ["London", "Manchester", "Edinburgh"]
        ),
        Country(
            code: "FR",
            name: "France",
            cities: ["Paris", "Nice", "Lyon", "Marseille"]
        ),
        Country(
            code: "ES",
            name: "Spain",
            cities: ["Barcelona", "Madrid", "Valencia", "Seville"]
        ),
        Country(
            code: "IT",
            name: "Italy",
            cities: ["Rome", "Milan", "Florence", "Venice", "Naples"]
        ),
        Country(
            code: "TR",
            name: "Türkiye",
            cities: ["Istanbul", "Antalya", "Cappadocia", "Izmir", "Ankara"]
        ),
        Country(
            code: "AE",
            name: "UAE",
            cities: ["Dubai", "Abu Dhabi"]
        ),
        Country(
            code: "JP",
            name: "Japan",
            cities: ["Tokyo", "Osaka", "Kyoto", "Sapporo", "Fukuoka"]
        ),
        Country(
            code: "TH",
            name: "Thailand",
            cities: ["Bangkok", "Phuket", "Chiang Mai", "Krabi"]
        ),
        Country(
            code: "RU",
            name: "Russia",
            cities: ["Москва", "Санкт-Петербург", "Казань", "Сочи", "Новосибирск"]
        )
    ]
}
