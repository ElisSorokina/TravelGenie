import Foundation

struct CountryModel: Identifiable, Codable, Hashable {
    var id: String { code }
    let code: String    // e.g. "US"
    let name: String    // e.g. "United States"
}

struct CityModel: Identifiable, Codable, Hashable {
    var id: String { name }
    let countryCode: String // matches CountryModel.code
    let name: String        // e.g. "New York"
}
