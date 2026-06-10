import Foundation

enum Constants {
    // Simulator için: "http://localhost:8080/api"
    // Gerçek cihaz için: static let apiBaseURL = "http://192.168.1.35:8080/api"
    static let apiBaseURL = "http://192.168.1.35:8080/api"
}

extension String {
    func formatIsoDate() -> String {
        let parser = ISO8601DateFormatter()
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let date = parser.date(from: self) ?? fallback.date(from: self)
        
        guard let date = date else { return self }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
    
    func parseIsoDate() -> Date? {
        let parser = ISO8601DateFormatter()
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return parser.date(from: self) ?? fallback.date(from: self)
    }
}

