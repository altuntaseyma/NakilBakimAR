import Foundation

final class APIService: ObservableObject {
    @Published var currentUser: User?
    @Published var accessToken: String = ""

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(Constants.apiBaseURL)/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try decoder.decode(LoginResponse.self, from: data)
        await MainActor.run {
            self.accessToken = response.accessToken
            self.currentUser = response.user
        }
        KeychainManager.shared.saveToken(response.accessToken)
    }
}

private struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}
