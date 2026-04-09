import SwiftUI
import ARKit
import RealityKit

struct ARExperienceView: View {
    @EnvironmentObject var api: APIService
    @State private var markerId = "marker_mobilization_v1"
    @State private var infoText = "Marker taramaya hazir."
    @State private var scenarioStart = Date()

    var body: some View {
        VStack(spacing: 12) {
            if ARImageTrackingConfiguration.isSupported {
                ARContainerView()
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ContentUnavailableView(
                    "Bu cihazda AR desteklenmiyor",
                    systemImage: "arkit",
                    description: Text("AR image tracking gercek cihazda kullanilabilir.")
                )
            }

            VStack(spacing: 10) {
                TextField("Marker ID", text: $markerId)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                Button("Marker icerigini backendden getir") {
                    Task { await loadMarkerContent() }
                }
                .buttonStyle(CustomButtonStyle())

                Text(infoText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if api.myProfile != nil {
                    HStack(spacing: 8) {
                        Button("Dogru Hareketi Yaptim") {
                            Task { await logDecision(option: "correct_pose", correct: true) }
                        }
                        .buttonStyle(CustomButtonStyle(tint: Color(hex: "#2E7D32")))

                        Button("Yanlis Hareket") {
                            Task { await logDecision(option: "wrong_pose", correct: false) }
                        }
                        .buttonStyle(CustomButtonStyle(tint: Color(hex: "#B23A48")))
                    }
                }
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding()
        .navigationTitle("AR")
    }

    private func loadMarkerContent() async {
        scenarioStart = Date()
        do {
            try await api.fetchARContent(markerId: markerId)
            if let content = api.arContent {
                infoText = "Model: \(content.modelUrl ?? "-") | Animasyon: \(content.animationType ?? "-")"
            } else {
                infoText = "Icerik bulunamadi."
            }
        } catch {
            infoText = "AR icerigi alinamadi: \(error.localizedDescription)"
        }
    }

    private func logDecision(option: String, correct: Bool) async {
        guard let patientId = api.myProfile?.id else { return }
        let duration = max(1, Int(Date().timeIntervalSince(scenarioStart)))
        do {
            try await api.logScenarioDecision(
                patientId: patientId,
                scenarioKey: "mobilization_ar",
                decisionKey: "pose_alignment",
                selectedOption: option,
                wasCorrect: correct,
                durationSec: duration
            )
            infoText = correct ? "Kaydedildi: Dogru hareket." : "Kaydedildi: Duzeltme onerisi olusturuldu."
        } catch {
            infoText = "Senaryo log kaydi basarisiz: \(error.localizedDescription)"
        }
    }
}

private struct ARContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let config = ARImageTrackingConfiguration()
        config.maximumNumberOfTrackedImages = 1

        if let images = ARReferenceImage.referenceImages(inGroupNamed: "ReferenceImages", bundle: .main) {
            config.trackingImages = images
        }

        view.session.run(config, options: [.removeExistingAnchors, .resetTracking])
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
