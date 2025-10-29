import Foundation

enum Back4AppError: LocalizedError {
    case badStatus(Int, String)
    case invalidResponse
    case decoding(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .badStatus(_, let msg): return msg
        case .invalidResponse: return "Invalid server response."
        case .decoding(let m): return "Decoding error: \(m)"
        case .network(let m):  return "Network error: \(m)"
        }
    }
}

struct ParseUser: Codable {
    let objectId: String
    let username: String?
    let email: String?
    let sessionToken: String?
    let name: String?
    let createdAt: String?
    let updatedAt: String?
}

private struct ParseErrorResponse: Codable {
    let code: Int
    let error: String
}

enum Back4AppService {

    // MARK: - Public API

    static func registerUser(name: String, email: String, password: String) async throws -> ParseUser {
        // Parse требует username — используем email как username
        let body: [String: Any] = [
            "username": email,
            "password": password,
            "email": email,
            "name": name
        ]
        let url = Secrets.parseBaseURL.appendingPathComponent("/users")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        applyParseHeaders(&req)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await perform(req)
        return try decode(ParseUser.self, from: data)
    }

    static func login(usernameOrEmail: String, password: String) async throws -> ParseUser {
        // Parse login: GET /login?username=...&password=...
        var comps = URLComponents(url: Secrets.parseBaseURL.appendingPathComponent("/login"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "username", value: usernameOrEmail),
            URLQueryItem(name: "password", value: password)
        ]
        guard let url = comps.url else { throw Back4AppError.invalidResponse }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        applyParseHeaders(&req)

        let data = try await perform(req)
        return try decode(ParseUser.self, from: data)
    }

    // MARK: - Helpers

    private static func applyParseHeaders(_ req: inout URLRequest) {
        req.addValue(Secrets.parseAppId, forHTTPHeaderField: "X-Parse-Application-Id")
        req.addValue(Secrets.parseRestKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
    }

    private static func perform(_ req: URLRequest) async throws -> Data {
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw Back4AppError.invalidResponse
            }
            if (200..<300).contains(http.statusCode) {
                return data
            } else {
                // попробуем вытащить текст ошибки Parse
                if let parseErr = try? JSONDecoder().decode(ParseErrorResponse.self, from: data) {
                    throw Back4AppError.badStatus(http.statusCode, parseErr.error)
                } else {
                    let txt = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw Back4AppError.badStatus(http.statusCode, txt)
                }
            }
        } catch let e as Back4AppError {
            throw e
        } catch {
            throw Back4AppError.network(error.localizedDescription)
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw Back4AppError.decoding("\(error) | raw: \(raw)")
        }
    }
}
