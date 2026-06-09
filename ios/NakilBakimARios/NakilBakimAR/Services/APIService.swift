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
    @Published var profileLoading = false
    @Published var nursePatientsLoading = false
    @Published var tasksLoading = false
    @Published var vitalsLoading = false
    @Published var modulesLoading = false
    @Published var dashboardLoading = false
    @Published var lastErrorMessage: String?

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

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateAuthResponse(data: data, response: response)
        let decodedResponse = try decoder.decode(LoginResponse.self, from: data)
        await MainActor.run {
            self.accessToken = decodedResponse.accessToken
            self.currentUser = decodedResponse.user
        }
        KeychainManager.shared.saveToken(decodedResponse.accessToken)
    }

    func loginPatient(tcNo: String, pin: String) async throws {
        guard let url = URL(string: "\(Constants.apiBaseURL)/auth/login/patient") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "tcNo": tcNo,
            "pin": pin
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateAuthResponse(data: data, response: response)
        let decodedResponse = try decoder.decode(LoginResponse.self, from: data)
        await MainActor.run {
            self.accessToken = decodedResponse.accessToken
            self.currentUser = decodedResponse.user
        }
        KeychainManager.shared.saveToken(decodedResponse.accessToken)
    }

    func registerPatientByNurse(
        fullName: String,
        tcNo: String,
        pin: String,
        transplantDateISO: String?
    ) async throws {
        let body = compactBody([
            "fullName": fullName,
            "tcNo": tcNo,
            "pin": pin,
            "transplantDate": transplantDateISO
        ])
        let _: NursePatientRegisterResponse = try await authedRequest(
            path: "/auth/register/patient",
            method: "POST",
            body: body
        )
        try await fetchNursePatients()
    }

    @MainActor
    func logout() {
        currentUser = nil
        accessToken = ""
        myProfile = nil
        tasks = []
        vitals = []
        patientModules = []
        scenarioSummary = nil
        lastErrorMessage = nil
        KeychainManager.shared.deleteToken()
    }

    func fetchNursePatients() async throws {
        await MainActor.run {
            nursePatientsLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in nursePatientsLoading = false } }
        do {
            let patients: [PatientProfile] = try await authedRequest(path: "/patients")
            await MainActor.run { self.nursePatients = patients }
        } catch {
            await publishError(error)
            throw error
        }
    }

    func fetchMyProfile() async throws {
        await MainActor.run {
            profileLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in profileLoading = false } }
        do {
            let profile: PatientProfile? = try await authedRequest(path: "/patients/me/profile")
            await MainActor.run { self.myProfile = profile }
        } catch {
            await publishError(error)
            throw error
        }
    }

    func fetchTasks(patientProfileId: UUID) async throws {
        await MainActor.run {
            tasksLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in tasksLoading = false } }
        do {
            let items: [TaskItem] = try await authedRequest(path: "/tasks/patient/\(patientProfileId.uuidString)")
            await MainActor.run { self.tasks = items }
        } catch {
            await publishError(error)
            throw error
        }
    }

    func fetchVitals(patientProfileId: UUID) async throws {
        await MainActor.run {
            vitalsLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in vitalsLoading = false } }
        do {
            let items: [VitalSign] = try await authedRequest(path: "/vitals/patient/\(patientProfileId.uuidString)")
            await MainActor.run { self.vitals = items }
        } catch {
            await publishError(error)
            throw error
        }
    }

    func fetchPatientModules(patientProfileId: UUID) async throws {
        await MainActor.run {
            modulesLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in modulesLoading = false } }
        do {
            let modules: [CareModule] = try await authedRequest(path: "/patients/\(patientProfileId.uuidString)/modules")
            await MainActor.run { self.patientModules = modules }
        } catch {
            await publishError(error)
            throw error
        }
    }

    func fetchMyModules() async throws {
        await MainActor.run {
            modulesLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in modulesLoading = false } }
        do {
            let modules: [CareModule] = try await authedRequest(path: "/patients/me/modules")
            await MainActor.run { self.patientModules = modules }
        } catch {
            await publishError(error)
            throw error
        }
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
        let body = compactBody([
            "patientId": patientProfileId.uuidString,
            "type": type,
            "title": title,
            "description": description,
            "scheduledTime": scheduledAtISO
        ])
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
        let body = compactBody([
            "patientId": patientProfileId.uuidString,
            "bodyTemperature": bodyTemperature,
            "bloodPressureSystolic": systolic,
            "bloodPressureDiastolic": diastolic,
            "heartRate": heartRate,
            "oxygenSaturation": oxygen,
            "notes": notes,
            "sharedWithPatient": sharedWithPatient,
            "recordedAt": recordedAtISO
        ])
        let _: EmptyResponse = try await authedRequest(
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

    func updateVitalShare(
        vitalId: UUID,
        patientProfileId: UUID,
        sharedWithPatient: Bool
    ) async throws {
        let body: [String: Any] = ["sharedWithPatient": sharedWithPatient]
        let _: VitalSign = try await authedRequest(
            path: "/vitals/share/\(vitalId.uuidString)",
            method: "PUT",
            body: body
        )
        try await fetchVitals(patientProfileId: patientProfileId)
    }

    func fetchARContent(markerId: String) async throws {
        let content: ARContent = try await authedRequest(path: "/ar/marker/\(markerId)")
        await MainActor.run { self.arContent = content }
    }

    func updatePatientOperation(
        patientId: UUID,
        transplantDateISO: String?
    ) async throws {
        let body = compactBody([
            "transplantDate": transplantDateISO
        ])
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
        let body = compactBody([
            "patientId": patientId.uuidString,
            "scenarioKey": scenarioKey,
            "decisionKey": decisionKey,
            "selectedOption": selectedOption,
            "wasCorrect": wasCorrect,
            "moduleDurationSec": durationSec
        ])
        let _: ScenarioLog = try await authedRequest(
            path: "/scenarios/log",
            method: "POST",
            body: body
        )
    }

    func fetchScenarioSummary(patientProfileId: UUID) async throws {
        await MainActor.run {
            dashboardLoading = true
            lastErrorMessage = nil
        }
        defer { Task { @MainActor in dashboardLoading = false } }
        do {
            let summary: ScenarioSummary = try await authedRequest(path: "/scenarios/patient/\(patientProfileId.uuidString)/summary")
            await MainActor.run { self.scenarioSummary = summary }
        } catch {
            await publishError(error)
            throw error
        }
    }

    @MainActor
    func clearLastError() {
        lastErrorMessage = nil
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
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateAuthResponse(data: data, response: response)
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try decoder.decode(T.self, from: data)
    }

    private func compactBody(_ raw: [String: Any?]) -> [String: Any] {
        raw.compactMapValues { value in
            guard let value else { return nil }
            if let optionalString = value as? String, optionalString.isEmpty {
                return optionalString
            }
            return value
        }
    }

    @MainActor
    private func publishError(_ error: Error) {
        lastErrorMessage = error.localizedDescription
    }

    private func validateAuthResponse(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            if let message = try? JSONDecoder().decode(APIErrorMessage.self, from: data).message,
               !message.isEmpty {
                throw NSError(domain: "APIService", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: message
                ])
            }
            throw NSError(domain: "APIService", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Sunucu girisi reddetti (HTTP \(http.statusCode))."
            ])
        }
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

private struct APIErrorMessage: Codable {
    let message: String
}

private struct NursePatientRegisterResponse: Codable {
    let user: User
    let profile: PatientProfile
}
