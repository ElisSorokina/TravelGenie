import Foundation

@MainActor
final class LocationService: ObservableObject {

    @Published var countries: [CountryModel] = []
    // кэш загруженных городов по коду страны:
    @Published private(set) var citiesByCountry: [String: [CityModel]] = [:]

    @Published var isLoadingCountries = false
    @Published var isLoadingCities: Set<String> = [] // множество countryCode, которые грузятся сейчас
    @Published var errorText: String?

    private let baseURL = Secrets.parseBaseURL
    private let appId   = Secrets.parseAppId
    private let apiKey  = Secrets.parseRestKey

    // MARK: - Public API

    func loadCountriesIfNeeded() async {
        guard countries.isEmpty else { return }
        await loadCountries()
    }

    func cities(for country: CountryModel) -> [CityModel] {
        citiesByCountry[country.code] ?? []
    }

    func loadCitiesIfNeeded(for country: CountryModel) async {
        if citiesByCountry[country.code] != nil {
            return // уже есть
        }
        await loadCities(for: country)
    }

    // MARK: - Internal loaders

    private func loadCountries() async {
        isLoadingCountries = true
        defer { isLoadingCountries = false }

        errorText = nil

        do {
            var req = URLRequest(url: baseURL.appendingPathComponent("classes/Country"))
            req.httpMethod = "GET"
            req.addValue(appId, forHTTPHeaderField: "X-Parse-Application-Id")
            req.addValue(apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            // Back4App "find" returns { "results": [ ... ] }
            struct CountryResponse: Codable {
                let results: [CountryObject]
            }
            struct CountryObject: Codable {
                let code: String
                let name: String
            }

            let decoded = try JSONDecoder().decode(CountryResponse.self, from: data)

            self.countries = decoded.results.map {
                CountryModel(code: $0.code, name: $0.name)
            }
            // сортируем по алфавиту
            self.countries.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        } catch {
            print("❌ loadCountries error:", error)
            errorText = "Failed to load countries"
        }
    }

    private func loadCities(for country: CountryModel) async {
        isLoadingCities.insert(country.code)
        defer { isLoadingCities.remove(country.code) }

        errorText = nil

        do {
            // Parse class City
            // We'll query ?where={"countryCode":"US"} etc.
            let whereDict = ["countryCode": country.code]
            let whereData = try JSONSerialization.data(withJSONObject: whereDict)
            let whereJSON = String(data: whereData, encoding: .utf8) ?? "{}"

            var comps = URLComponents(url: baseURL.appendingPathComponent("classes/City"), resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                URLQueryItem(name: "where", value: whereJSON),
                URLQueryItem(name: "limit", value: "2000")
            ]

            guard let url = comps.url else { throw URLError(.badURL) }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.addValue(appId, forHTTPHeaderField: "X-Parse-Application-Id")
            req.addValue(apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            struct CityResponse: Codable {
                let results: [CityObject]
            }
            struct CityObject: Codable {
                let countryCode: String
                let name: String
            }

            let decoded = try JSONDecoder().decode(CityResponse.self, from: data)
            let mapped = decoded.results.map {
                CityModel(countryCode: $0.countryCode, name: $0.name)
            }
            let sorted = mapped.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            citiesByCountry[country.code] = sorted

        } catch {
            print("❌ loadCities error:", error)
            errorText = "Failed to load cities"
        }
    }
}
