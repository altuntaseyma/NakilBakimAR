import Foundation
import Combine

final class APIService: ObservableObject {
    @Published var currentUser: User?
    @Published var accessToken: String = ""
    @Published var nursePatients: [PatientProfile] = []
    @Published var myProfile: PatientProfile?
    @Published var tasks: [TaskItem] = []
    @Published var vitals: [VitalSign] = []
    @Published var patientModules: [CareModule] = []
    @Published var arContent: ARContent?
    @Published var scenarioSummary: ScenarioSummary?

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

    func fetchNursePatients() async throws {
        let patients: [PatientProfile] = try await authedRequest(path: "/patients")
        await MainActor.run { self.nursePatients = patients }
    }

    func fetchMyProfile() async throws {
        let profile: PatientProfile? = try await authedRequest(path: "/patients/me/profile")
        await MainActor.run { self.myProfile = profile }
    }

    func fetchTasks(patientProfileId: UUID) async throws {
        let items: [TaskItem] = try await authedRequest(path: "/tasks/patient/\(patientProfileId.uuidString)")
        await MainActor.run { self.tasks = items }
    }

    func fetchVitals(patientProfileId: UUID) async throws {
        let items: [VitalSign] = try await authedRequest(path: "/vitals/patient/\(patientProfileId.uuidString)")
        await MainActor.run { self.vitals = items }
    }

    func fetchPatientModules(patientProfileId: UUID) async throws {
        let modules: [CareModule] = try await authedRequest(path: "/patients/\(patientProfileId.uuidString)/modules")
        await MainActor.run { self.patientModules = modules }
    }

    func fetchMyModules() async throws {
        let modules: [CareModule] = try await authedRequest(path: "/patients/me/modules")
        await MainActor.run { self.patientModules = modules }
    }

    func updatePatientModules(patientProfileId: UUID, modules: [CareModule]) async throws {
        let bodyModules = modules.map { ["moduleId": $0.id, "isEnabled": $0.isEnabled] }
        let body: [String: Any] = ["modules": bodyModules]
        let _: UpdateSuccess = try await authedRequest(
            path: "/patients/\(patientProfileId.uuidString)/modules",
            method: "PUT",
            body: body
        )
        await MainActor.run { self.patientModules = modules }
    }

    func createTask(patientProfileId: UUID, type: String, title: String, description: String, scheduledAtISO: String?) async throws {
        let body: [String: Any] = [
            "patientId": patientProfileId.uuidString,
            "type": type,
            "title": title,
            "description": description,
            "scheduledTime": scheduledAtISO as Any
        ]
        let _: TaskItem = try await authedRequest(
            path: "/tasks",
            method: "POST",
            body: body
        )
        try await fetchTasks(patientProfileId: patientProfileId)
    }

    func completeTask(taskId: UUID, patientProfileId: UUID) async throws {
        let body: [String: Any] = ["isCompleted": true]
        let _: TaskItem = try await authedRequest(
            path: "/tasks/\(taskId.uuidString)",
            method: "PUT",
            body: body
        )
        try await fetchTasks(patientProfileId: patientProfileId)
    }

    func deleteTask(taskId: UUID, patientProfileId: UUID) async throws {
        let _: EmptyResponse = try await authedRequest(
            path: "/tasks/\(taskId.uuidString)",
            method: "DELETE"
        )
        try await fetchTasks(patientProfileId: patientProfileId)
    }

    func createVital(
        patientProfileId: UUID,
        bodyTemperature: Double?,
        systolic: Int?,
        diastolic: Int?,
        heartRate: Int?,
        oxygen: Int?,
        notes: String,
        sharedWithPatient: Bool,
        recordedAtISO: String?
    ) async throws {
        let body: [String: Any] = [
            "patientId": patientProfileId.uuidString,
            "bodyTemperature": bodyTemperature as Any,
            "bloodPressureSystolic": systolic as Any,
            "bloodPressureDiastolic": diastolic as Any,
            "heartRate": heartRate as Any,
            "oxygenSaturation": oxygen as Any,
            "notes": notes,
            "sharedWithPatient": sharedWithPatient,
            "recordedAt": recordedAtISO as Any
        ]
        let _: VitalSign = try await authedRequest(
            path: "/vitals",
            method: "POST",
            body: body
        )
        try await fetchVitals(patientProfileId: patientProfileId)
    }

    func deleteVital(vitalId: UUID, patientProfileId: UUID) async throws {
        let _: EmptyResponse = try await authedRequest(
            path: "/vitals/\(vitalId.uuidString)",
            method: "DELETE"
        )
        try await fetchVitals(patientProfileId: patientProfileId)
    }

    func fetchARContent(markerId: String) async throws {
        let content: ARContent = try await authedRequest(path: "/ar/marker/\(markerId)")
        await MainActor.run { self.arContent = content }
    }

    func updatePatientOperation(
        patientId: UUID,
        transplantDateISO: String?,
        setPreOp: Bool
    ) async throws {
        let body: [String: Any] = [
            "transplantDate": transplantDateISO as Any,
            "setPreOp": setPreOp
        ]
        let _: PatientProfile = try await authedRequest(
            path: "/patients/\(patientId.uuidString)/operation",
            method: "PUT",
            body: body
        )
        try await fetchNursePatients()
    }

    func logScenarioDecision(
        patientId: UUID,
        scenarioKey: String,
        decisionKey: String,
        selectedOption: String,
        wasCorrect: Bool,
        durationSec: Int
    ) async throws {
        let body: [String: Any] = [
            "patientId": patientId.uuidString,
            "scenarioKey": scenarioKey,
            "decisionKey": decisionKey,
            "selectedOption": selectedOption,
            "wasCorrect": wasCorrect,
            "moduleDurationSec": durationSec
        ]
        let _: ScenarioLog = try await authedRequest(
            path: "/scenarios/log",
            method: "POST",
            body: body
        )
    }

    func fetchScenarioSummary(patientProfileId: UUID) async throws {
        let summary: ScenarioSummary = try await authedRequest(path: "/scenarios/patient/\(patientProfileId.uuidString)/summary")
        await MainActor.run { self.scenarioSummary = summary }
    }

    private func authedRequest<T: Decodable>(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(Constants.apiBaseURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, _) = try await URLSession.shared.data(for: request)
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try decoder.decode(T.self, from: data)
    }
}

private struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

private struct UpdateSuccess: Codable {
    let success: Bool
}

private struct EmptyResponse: Codable {
    init() {}
}

private struct ScenarioLog: Codable {
    let id: UUID
}
