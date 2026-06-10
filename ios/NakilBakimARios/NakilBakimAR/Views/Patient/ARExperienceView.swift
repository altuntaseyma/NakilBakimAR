import SwiftUI
import ARKit
import RealityKit
import Combine

// MARK: - ARExperienceView

struct ARExperienceView: View {
    enum ScenarioMode {
        case mobilization
        case medication

        var markerId: String {
            switch self {
            case .mobilization: return "ar_exercise_brochure"
            case .medication:   return "ar_medication_box"
            }
        }

        var title: String {
            switch self {
            case .mobilization: return "AR Egzersiz Rehberi"
            case .medication:   return "AR Ilaç Rehberi"
            }
        }

        var scenarioKey: String {
            switch self {
            case .mobilization: return "mobilization_ar"
            case .medication:   return "medication_ar"
            }
        }

        var decisionKey: String {
            switch self {
            case .mobilization: return "pose_alignment"
            case .medication:   return "dose_understanding"
            }
        }

        var accentColor: Color {
            switch self {
            case .mobilization: return InonuPalette.exerciseBlue
            case .medication:   return InonuPalette.medicationPurple
            }
        }
    }

    @EnvironmentObject var api: APIService
    let mode: ScenarioMode

    @State private var markerDetected = false
    @State private var detectedExerciseIndex = 0
    @State private var scanningPulse = false
    @State private var arStatusText = "Broşürü kameraya gösterin"
    @State private var scenarioStart = Date()
    @State private var decisionLogged = false
    @State private var showSuccessBanner = false

    var body: some View {
        ZStack {
            // AR kamera arka plan
            if ARImageTrackingConfiguration.isSupported {
                ARContainerView(
                    mode: mode,
                    hasPendingMedication: hasPendingMedication,
                    detectedExerciseIndex: detectedExerciseIndex,
                    onMarkerDetected: { exerciseIdx in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            markerDetected = true
                            detectedExerciseIndex = exerciseIdx
                            arStatusText = "Marker algilandi!"
                        }
                        HapticEngine.success()
                        Task { await autoLogDecision() }
                    },
                    onMarkerLost: {
                        withAnimation(.easeOut(duration: 0.4)) {
                            markerDetected = false
                            arStatusText = "Broşürü kameraya gösterin"
                        }
                    }
                )
                .ignoresSafeArea()
            } else {
                // Simulator fallback
                simulatorFallback
            }

            // Üst HUD katmanı
            VStack(spacing: 0) {
                topHUD
                Spacer()
                bottomPanel
                    .padding(.bottom, 90) // Tab Bar ile çakışmaması için pay eklendi
            }
            .ignoresSafeArea(edges: .bottom)

            // Marker algılama başarı banner
            if showSuccessBanner {
                successBannerOverlay
            }

            // Tarama animasyonu (marker bulunamadığında)
            if !markerDetected && ARImageTrackingConfiguration.isSupported {
                scanningOverlay
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { scenarioStart = Date() }
    }

    // MARK: - Simulator Fallback

    private var simulatorFallback: some View {
        ZStack {
            LinearGradient(
                colors: [
                    mode.accentColor.opacity(0.12),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "arkit")
                        .font(.system(size: 52))
                        .foregroundStyle(mode.accentColor)
                }

                VStack(spacing: 8) {
                    Text("Simulator Modu")
                        .font(.title2.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    Text("AR kamera gerçek cihazda çalışır.\nAşağıdaki simulasyon modunu kullanın.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Simulator demo butonları
                VStack(spacing: 12) {
                    ForEach(exerciseSteps.indices, id: \.self) { idx in
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                markerDetected = true
                                detectedExerciseIndex = idx
                                arStatusText = "Simülasyon: \(exerciseSteps[idx].name)"
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(idx + 1)")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(mode.accentColor)
                                    .clipShape(Circle())
                                Text(exerciseSteps[idx].name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(InonuPalette.deepNavy)
                                Spacer()
                                Image(systemName: exerciseSteps[idx].icon)
                                    .foregroundStyle(mode.accentColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: mode.accentColor.opacity(0.08), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 60)
        }
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack(spacing: 12) {
            Image(systemName: "arkit")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text(arStatusText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Marker durumu göstergesi
            HStack(spacing: 6) {
                Circle()
                    .fill(markerDetected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(markerDetected ? 1.0 : (scanningPulse ? 1.3 : 0.8))
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scanningPulse)
                Text(markerDetected ? "Aktif" : "Taranıyor")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .onAppear { scanningPulse = true }
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            if markerDetected {
                detectedPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                idlePanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: markerDetected)
    }

    // MARK: - Idle Panel (Marker Bulunamadı)

    private var idlePanel: some View {
        VStack(spacing: 16) {
            // Egzersiz listesi önizlemesi
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exerciseSteps.indices, id: \.self) { idx in
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(mode.accentColor.opacity(0.12))
                                    .frame(width: 72, height: 72)
                                Image(systemName: exerciseSteps[idx].icon)
                                    .font(.title2)
                                    .foregroundStyle(mode.accentColor)
                            }
                            Text("\(idx + 1). \(exerciseSteps[idx].shortName)")
                                .font(.caption2.bold())
                                .foregroundStyle(InonuPalette.deepNavy)
                                .multilineTextAlignment(.center)
                                .frame(width: 72)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Text("Broşürü kameraya tutun — egzersizler ekranda canlanacak")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Detected Panel (Marker Bulundu)

    private var detectedPanel: some View {
        let step = exerciseSteps[detectedExerciseIndex]

        return VStack(spacing: 0) {
            // Üst kayar sekme — egzersiz navigasyonu
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(exerciseSteps.indices, id: \.self) { idx in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                detectedExerciseIndex = idx
                            }
                            HapticEngine.light()
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(idx == detectedExerciseIndex ? mode.accentColor : mode.accentColor.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: exerciseSteps[idx].icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(idx == detectedExerciseIndex ? .white : mode.accentColor)
                                }
                                Text("\(idx + 1)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(idx == detectedExerciseIndex ? mode.accentColor : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)

            Divider()

            // Ana egzersiz detay kartı
            HStack(spacing: 16) {
                // İkon + numara
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(mode.accentColor.opacity(0.14))
                        .frame(width: 64, height: 64)
                    VStack(spacing: 2) {
                        Image(systemName: step.icon)
                            .font(.title2)
                            .foregroundStyle(mode.accentColor)
                        Text("\(detectedExerciseIndex + 1)/\(exerciseSteps.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(mode.accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.name)
                        .font(.headline.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    Text(step.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Set / Rep bilgisi
                    HStack(spacing: 12) {
                        Label(step.sets, systemImage: "repeat")
                            .font(.caption.bold())
                            .foregroundStyle(mode.accentColor)
                        Label(step.reps, systemImage: "timer")
                            .font(.caption.bold())
                            .foregroundStyle(mode.accentColor)
                    }
                    .padding(.top, 2)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Karar butonları
            if api.myProfile != nil && !decisionLogged {
                HStack(spacing: 10) {
                    Button {
                        Task { await logDecision(correct: true) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Yaptım!")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.18, green: 0.72, blue: 0.44))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await logDecision(correct: false) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Yapamadım")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.93, green: 0.32, blue: 0.32))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            } else if decisionLogged {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.44))
                    Text("Karar kaydedildi. Sonraki egzersize geçebilirsin.")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Scanning Overlay

    private var scanningOverlay: some View {
        VStack {
            Spacer()
            Spacer()
            ZStack {
                // Köşe tarama çerçevesi
                ScanFrameView(color: mode.accentColor)
                    .frame(width: 220, height: 220)

                // Tarama çizgisi animasyonu
                ScanLineView(color: mode.accentColor)
                    .frame(width: 220, height: 220)
            }
            Spacer()
            Spacer()
            Spacer()
        }
    }

    // MARK: - Success Banner

    private var successBannerOverlay: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                Text("Harika! Egzersiz tamamlandı.")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.18, green: 0.72, blue: 0.44))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.top, 100)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Logic

    private func autoLogDecision() async {
        guard !decisionLogged else { return }
        // Marker algılandığında otomatik senaryo başlatma logu
        guard let patientId = api.myProfile?.id else { return }
        let duration = max(1, Int(Date().timeIntervalSince(scenarioStart)))
        try? await api.logScenarioDecision(
            patientId: patientId,
            scenarioKey: mode.scenarioKey,
            decisionKey: "marker_detected",
            selectedOption: "brochure_scanned",
            wasCorrect: true,
            durationSec: duration
        )
    }

    private func logDecision(correct: Bool) async {
        guard let patientId = api.myProfile?.id else { return }
        let duration = max(1, Int(Date().timeIntervalSince(scenarioStart)))
        try? await api.logScenarioDecision(
            patientId: patientId,
            scenarioKey: mode.scenarioKey,
            decisionKey: mode.decisionKey + "_\(detectedExerciseIndex + 1)",
            selectedOption: correct ? "exercise_done" : "exercise_skipped",
            wasCorrect: correct,
            durationSec: duration
        )
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                decisionLogged = true
                if correct {
                    showSuccessBanner = true
                }
            }
        }
        if correct {
            HapticEngine.success()
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation { showSuccessBanner = false }
                // Sonraki egzersize geç
                if detectedExerciseIndex < exerciseSteps.count - 1 {
                    detectedExerciseIndex += 1
                    decisionLogged = false
                }
            }
        }
    }

    private var hasPendingMedication: Bool {
        api.tasks.filter { $0.type == "medication" && !$0.isCompleted }.count > 0
    }

    // MARK: - Exercise Data

    struct ExerciseStep {
        let name: String
        let shortName: String
        let description: String
        let icon: String
        let sets: String
        let reps: String
    }

    var exerciseSteps: [ExerciseStep] {
        switch mode {
        case .mobilization:
            return [
                ExerciseStep(
                    name: "Üst Beden Sağ-Sol",
                    shortName: "Gövde",
                    description: "Üst bedeninizi yavaşça sağa ve sola çevirin. Hareketi kontrollü yapın.",
                    icon: "arrow.left.and.right",
                    sets: "3 set",
                    reps: "10 tekrar"
                ),
                ExerciseStep(
                    name: "Derin Nefes",
                    shortName: "Nefes",
                    description: "Burnunuzdan 3-4 sn alın, 2 sn tutun, 4-6 sn ağızdan verin.",
                    icon: "wind",
                    sets: "3 seans",
                    reps: "10 nefes"
                ),
                ExerciseStep(
                    name: "Kol Germe",
                    shortName: "Kol",
                    description: "Kolunuzu yanlara açın, 15 saniye tutun. Gerginliği hissedin.",
                    icon: "figure.arms.open",
                    sets: "2 set",
                    reps: "15 sn tutun"
                ),
                ExerciseStep(
                    name: "Diz Pompası",
                    shortName: "Diz",
                    description: "Oturarak ayak bileklerinizi yukarı kaldırıp indirin. Dolaşımı artırır.",
                    icon: "figure.seated.seatbelt",
                    sets: "3 set",
                    reps: "20 tekrar"
                ),
                ExerciseStep(
                    name: "Oturma / Kalkma",
                    shortName: "Kalkış",
                    description: "Sandalyeden desteksiz kalkın ve oturun. Denge ve güç kazandırır.",
                    icon: "figure.stand",
                    sets: "3 set",
                    reps: "8 tekrar"
                ),
                ExerciseStep(
                    name: "Yürüyüş",
                    shortName: "Yürüyüş",
                    description: "Gün içinde düzenli koridorda yürüyüş yapın. Süreyi kademeli artırın.",
                    icon: "figure.walk",
                    sets: "Günde 3 kez",
                    reps: "5-10 dk"
                ),
            ]

        case .medication:
            return [
                ExerciseStep(
                    name: "Sabah Dozu — Takrolimus",
                    shortName: "Takrolimus",
                    description: "Sabah aç karnına alınır. Greyfurt suyu ile alınmamalıdır. Kan düzeyi düzenli izlenir.",
                    icon: "pill.fill",
                    sets: "Günde 2 kez",
                    reps: "08:00 / 20:00"
                ),
                ExerciseStep(
                    name: "Mikofenolat Mofetil",
                    shortName: "MMF",
                    description: "Yemekle birlikte alınır. Mide bulantısı oluşursa hemşireye bildiriniz.",
                    icon: "capsule.fill",
                    sets: "Günde 2 kez",
                    reps: "08:00 / 20:00"
                ),
                ExerciseStep(
                    name: "Prednizolon",
                    shortName: "Prednizolon",
                    description: "Kahvaltıyla birlikte alınır. Kan şekeri izlemi gerektirir.",
                    icon: "pill.circle.fill",
                    sets: "Günde 1 kez",
                    reps: "08:00"
                ),
                ExerciseStep(
                    name: "Antiviral Profilaksi",
                    shortName: "Antiviral",
                    description: "Valgansiklovir öğle yemeğiyle alınır. CMV enfeksiyonuna karşı koruyucudur.",
                    icon: "shield.fill",
                    sets: "Günde 1 kez",
                    reps: "12:00"
                ),
                ExerciseStep(
                    name: "Antibiyotik Profilaksi",
                    shortName: "Antibiyotik",
                    description: "TMP-SMX haftada 3 gün (Pazartesi-Çarşamba-Cuma) alınır.",
                    icon: "cross.fill",
                    sets: "Haftada 3 kez",
                    reps: "10:00"
                ),
                ExerciseStep(
                    name: "Mide Koruyucu",
                    shortName: "Omeprazol",
                    description: "Kahvaltıdan 30 dk önce alınır. Mide asiditesini dengeler.",
                    icon: "heart.fill",
                    sets: "Günde 1 kez",
                    reps: "07:30"
                ),
            ]
        }
    }
}

// MARK: - Scan Frame View

private struct ScanFrameView: View {
    let color: Color
    private let cornerLength: CGFloat = 28
    private let lineWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Dört köşe
                Group {
                    // Sol üst
                    cornerShape(rotation: 0)
                        .position(x: cornerLength / 2, y: cornerLength / 2)
                    // Sağ üst
                    cornerShape(rotation: 90)
                        .position(x: w - cornerLength / 2, y: cornerLength / 2)
                    // Sol alt
                    cornerShape(rotation: 270)
                        .position(x: cornerLength / 2, y: h - cornerLength / 2)
                    // Sağ alt
                    cornerShape(rotation: 180)
                        .position(x: w - cornerLength / 2, y: h - cornerLength / 2)
                }
            }
        }
    }

    private func cornerShape(rotation: Double) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: cornerLength))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: cornerLength, y: 0))
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: cornerLength, height: cornerLength)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Scan Line View

private struct ScanLineView: View {
    let color: Color
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, color.opacity(0.7), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: true)) {
                        offset = geo.size.height - 4
                    }
                }
        }
    }
}

// MARK: - Haptic Engine

private enum HapticEngine {
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
}

// MARK: - ARContainerView (UIViewRepresentable)

private struct ARContainerView: UIViewRepresentable {
    let mode: ARExperienceView.ScenarioMode
    let hasPendingMedication: Bool
    let detectedExerciseIndex: Int
    let onMarkerDetected: (Int) -> Void
    let onMarkerLost: () -> Void

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.renderOptions = [.disableMotionBlur, .disableDepthOfField]
        context.coordinator.arView = arView
        
        let config = ARImageTrackingConfiguration()
        config.maximumNumberOfTrackedImages = 2
        
        if let group = ARReferenceImage.referenceImages(inGroupNamed: "ReferenceImages", bundle: .main),
           !group.isEmpty {
            config.trackingImages = group
        }

        arView.session.delegate = context.coordinator
        arView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.hasPendingMedication = hasPendingMedication
        context.coordinator.mode = mode
        
        if context.coordinator.currentExerciseIndex != detectedExerciseIndex {
            context.coordinator.updateExercise(to: detectedExerciseIndex)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            mode: mode,
            hasPendingMedication: hasPendingMedication,
            onMarkerDetected: onMarkerDetected,
            onMarkerLost: onMarkerLost
        )
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, ARSessionDelegate {
        var mode: ARExperienceView.ScenarioMode
        var hasPendingMedication: Bool
        private let onMarkerDetected: (Int) -> Void
        private let onMarkerLost: () -> Void
        weak var arView: ARView?

        // Hangi egzersizin şu an gösterildiğini takip et
        var currentExerciseIndex = 0
        private var detectedAnchors: [UUID: AnchorEntity] = [:]
        private var floatTimer: Timer?
        
        // Dinamik güncellemeler için referanslar
        private var exerciseAnimTimer: Timer?
        private var currentExerciseVisuals: Entity?
        private var cosmonautEntity: Entity?
        private var cancellables = Set<AnyCancellable>()
        
        private let targetModelSize: Float = 0.10
        
        // Base transform for reset
        private var basePosition: SIMD3<Float> = .zero
        private var baseScale: SIMD3<Float> = .one
        private var baseOrientation: simd_quatf = simd_quatf(angle: 0, axis: [1, 0, 0])

        init(
            mode: ARExperienceView.ScenarioMode,
            hasPendingMedication: Bool,
            onMarkerDetected: @escaping (Int) -> Void,
            onMarkerLost: @escaping () -> Void
        ) {
            self.mode = mode
            self.hasPendingMedication = hasPendingMedication
            self.onMarkerDetected = onMarkerDetected
            self.onMarkerLost = onMarkerLost
        }

        // MARK: - AR Session Delegate

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let arView = arView else { return }
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                let imageName = imageAnchor.referenceImage.name ?? ""

                let anchorEntity = AnchorEntity(anchor: imageAnchor)
                detectedAnchors[anchor.identifier] = anchorEntity

                if imageName.contains("exercise") || imageName.contains("brochure") || imageName.contains("mobilization") {
                    buildExerciseOverlay(on: anchorEntity, index: currentExerciseIndex)
                    DispatchQueue.main.async {
                        self.onMarkerDetected(self.currentExerciseIndex)
                    }
                } else if imageName.contains("medication") || imageName.contains("med") {
                    buildMedicationOverlay(on: anchorEntity)
                    DispatchQueue.main.async {
                        self.onMarkerDetected(0)
                    }
                }

                arView.scene.addAnchor(anchorEntity)
                startFloatAnimation(for: anchorEntity)
            }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let entity = detectedAnchors.removeValue(forKey: anchor.identifier) {
                    arView?.scene.removeAnchor(entity)
                }
                DispatchQueue.main.async { self.onMarkerLost() }
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                if let entity = detectedAnchors[anchor.identifier] {
                    if imageAnchor.isTracked {
                        if !entity.isEnabled {
                            entity.isEnabled = true
                            DispatchQueue.main.async { self.onMarkerDetected(self.currentExerciseIndex) }
                        }
                    } else {
                        if entity.isEnabled {
                            entity.isEnabled = false
                            DispatchQueue.main.async { self.onMarkerLost() }
                        }
                    }
                }
            }
        }

        // MARK: - Exercise Overlay Builder

        private func buildExerciseOverlay(on anchor: AnchorEntity, index: Int) {

            // --- Human Yükle (Async) ---
            Entity.loadAsync(named: "human")
                .sink(receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Human yuklenemedi: \(error)")
                        DispatchQueue.main.async {
                            let errorLabel = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 200))
                            errorLabel.numberOfLines = 0
                            errorLabel.text = "⚠️ MODEL YÜKLENEMEDİ:\n\(error.localizedDescription)"
                            errorLabel.textColor = .white
                            errorLabel.backgroundColor = .red
                            errorLabel.font = .boldSystemFont(ofSize: 16)
                            self?.arView?.addSubview(errorLabel)
                        }
                    }
                }, receiveValue: { [weak self, weak anchor] human in
                    guard let self = self, let anchor = anchor else { return }

                    // 1) Wrapper oluştur
                    let wrapper = Entity()
                    wrapper.position = [0, 0.03, -0.02]
                    wrapper.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
                    anchor.addChild(wrapper)

                    self.basePosition = wrapper.position
                    self.baseScale = wrapper.scale
                    self.baseOrientation = wrapper.orientation

                    // 2) Modeli sıfırla ve başaşağı durmayı düzelt (180 derece döndür)
                    human.position = .zero
                    human.scale = SIMD3<Float>(repeating: 1.0)
                    human.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])

                    // 3) Model sadece wrapper içine eklensin
                    wrapper.addChild(human)

                    // 4) Modelin gerçek sınırlarını hesapla
                    let rawBounds = human.visualBounds(relativeTo: wrapper)

                    print("RAW BOUNDS center:", rawBounds.center)
                    print("RAW BOUNDS extents:", rawBounds.extents)

                    // 5) Y, Z karışmasın diye en büyük boyutu baz al
                    let maxDimension = max(rawBounds.extents.x, rawBounds.extents.y, rawBounds.extents.z)

                    let dynamicScale: Float
                    if maxDimension > 0.001 {
                        dynamicScale = self.targetModelSize / maxDimension
                    } else {
                        dynamicScale = 0.01
                    }

                    human.scale = SIMD3<Float>(repeating: dynamicScale)

                    // 6) Scale sonrası tekrar bounds al
                    let scaledBounds = human.visualBounds(relativeTo: wrapper)

                    // 7) Modelin merkezini wrapper merkezine çek
                    human.position.x -= scaledBounds.center.x
                    human.position.y -= scaledBounds.center.y
                    human.position.z -= scaledBounds.center.z

                    // 8) Alt kısmı broşürün üstüne kaldır
                    let finalBounds = human.visualBounds(relativeTo: wrapper)
                    let bottomY = finalBounds.center.y - finalBounds.extents.y / 2
                    human.position.y -= bottomY
                    human.position.y += 0.005

                    self.cosmonautEntity = wrapper
                })
                .store(in: &cancellables)
            
            // Ilk metinleri guncelle
            updateExercise(to: index)
        }
        
        func updateExercise(to index: Int) {
            currentExerciseIndex = index
            if cosmonautEntity != nil {
                stopCurrentExerciseAnimation()
                resetHumanTransform()
                
                switch index {
                case 0:
                    startUpperBodySideToSideAnimation()
                case 1:
                    startBreathingAnimation()
                case 2:
                    startArmStretchAnimation()
                case 3:
                    startKneePumpAnimation()
                case 4:
                    startSitStandAnimation()
                case 5:
                    startWalkingAnimation()
                default:
                    startUpperBodySideToSideAnimation()
                }
            }
        }
        
        private func stopCurrentExerciseAnimation() {
            exerciseAnimTimer?.invalidate()
            exerciseAnimTimer = nil
        }
        
        private func resetHumanTransform() {
            guard let humanWrapper = cosmonautEntity else { return }
            humanWrapper.position = basePosition
            humanWrapper.scale = baseScale
            humanWrapper.orientation = baseOrientation
            
            currentExerciseVisuals?.removeFromParent()
            currentExerciseVisuals = nil
        }
        
        private func setupVisualContainer() -> Entity {
            let container = Entity()
            cosmonautEntity?.addChild(container)
            currentExerciseVisuals = container
            return container
        }
        
        private func createTextVisual(text: String, size: CGFloat, color: UIColor, position: SIMD3<Float>) -> ModelEntity {
            let mesh = MeshResource.generateText(text, extrusionDepth: 0.002, font: .boldSystemFont(ofSize: size))
            var mat = UnlitMaterial()
            mat.color = .init(tint: color)
            let entity = ModelEntity(mesh: mesh, materials: [mat])
            
            let bounds = entity.visualBounds(relativeTo: nil)
            entity.position = position
            entity.position.x -= bounds.center.x
            entity.position.y -= bounds.center.y
            entity.position.z -= bounds.center.z
            
            return entity
        }
        
        private func startUpperBodySideToSideAnimation() {
            guard cosmonautEntity != nil else { return }
            let container = setupVisualContainer()
            let textEntity = createTextVisual(text: "↔", size: 0.05, color: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), position: [0, 0.06, 0.04])
            container.addChild(textEntity)
            
            exerciseAnimTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self, let wrapper = self.cosmonautEntity else { return }
                var t1 = wrapper.transform
                t1.rotation = self.baseOrientation * simd_quatf(angle: .pi / 18, axis: [0, 1, 0])
                wrapper.move(to: t1, relativeTo: wrapper.parent, duration: 1.0, timingFunction: .easeInOut)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    var t2 = wrapper.transform
                    t2.rotation = self.baseOrientation * simd_quatf(angle: -.pi / 18, axis: [0, 1, 0])
                    wrapper.move(to: t2, relativeTo: wrapper.parent, duration: 1.0, timingFunction: .easeInOut)
                }
            }
            exerciseAnimTimer?.fire()
        }

        private func startBreathingAnimation() {
            guard cosmonautEntity != nil else { return }
            let container = setupVisualContainer()
            
            let textEntity = createTextVisual(text: "〰", size: 0.04, color: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), position: [0, 0.09, 0.04])
            container.addChild(textEntity)
            
            exerciseAnimTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                guard let self = self, let wrapper = self.cosmonautEntity else { return }
                var t1 = wrapper.transform
                t1.scale = self.baseScale * 1.07
                wrapper.move(to: t1, relativeTo: wrapper.parent, duration: 1.5, timingFunction: .easeInOut)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    var t2 = wrapper.transform
                    t2.scale = self.baseScale
                    wrapper.move(to: t2, relativeTo: wrapper.parent, duration: 1.5, timingFunction: .easeInOut)
                }
            }
            exerciseAnimTimer?.fire()
        }

        private func startArmStretchAnimation() {
            guard cosmonautEntity != nil else { return }
            let container = setupVisualContainer()
            let textEntity = createTextVisual(text: "↔", size: 0.05, color: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), position: [0, 0.08, 0.04])
            container.addChild(textEntity)
            
            exerciseAnimTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self, let wrapper = self.cosmonautEntity else { return }
                var t1 = wrapper.transform
                t1.rotation = self.baseOrientation * simd_quatf(angle: .pi / 30, axis: [0, 0, 1]) // 6 degrees
                wrapper.move(to: t1, relativeTo: wrapper.parent, duration: 1.0, timingFunction: .easeInOut)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    var t2 = wrapper.transform
                    t2.rotation = self.baseOrientation * simd_quatf(angle: -.pi / 30, axis: [0, 0, 1])
                    wrapper.move(to: t2, relativeTo: wrapper.parent, duration: 1.0, timingFunction: .easeInOut)
                }
            }
            exerciseAnimTimer?.fire()
        }

        private func startKneePumpAnimation() {
            guard cosmonautEntity != nil else { return }
            let container = setupVisualContainer()
            let textEntity = createTextVisual(text: "↕", size: 0.04, color: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), position: [0, 0.025, 0.04])
            container.addChild(textEntity)
            
            exerciseAnimTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
                guard let self = self, let wrapper = self.cosmonautEntity else { return }
                var t1 = wrapper.transform
                t1.translation.y = self.basePosition.y + 0.015
                wrapper.move(to: t1, relativeTo: wrapper.parent, duration: 0.4, timingFunction: .easeInOut)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    var t2 = wrapper.transform
                    t2.translation.y = self.basePosition.y
                    wrapper.move(to: t2, relativeTo: wrapper.parent, duration: 0.4, timingFunction: .easeInOut)
                }
            }
            exerciseAnimTimer?.fire()
        }

        private func startSitStandAnimation() {
            guard cosmonautEntity != nil else { return }
            let container = setupVisualContainer()
            let textEntity = createTextVisual(text: "↕", size: 0.06, color: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), position: [0.06, 0.06, 0])
            container.addChild(textEntity)
            
            exerciseAnimTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                guard let self = self, let wrapper = self.cosmonautEntity else { return }
                var t1 = wrapper.transform
                t1.translation.y = self.basePosition.y - 0.035
                t1.rotation = self.baseOrientation * simd_quatf(angle: .pi / 12, axis: [1, 0, 0]) // öne eğilme
                wrapper.move(to: t1, relativeTo: wrapper.parent, duration: 1.5, timingFunction: .easeInOut)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    var t2 = wrapper.transform
                    t2.translation.y = self.basePosition.y
                    t2.rotation = self.baseOrientation
                    wrapper.move(to: t2, relativeTo: wrapper.parent, duration: 1.5, timingFunction: .easeInOut)
                }
            }
            exerciseAnimTimer?.fire()
        }

        private func startWalkingAnimation() {
            guard cosmonautEntity != nil else { return }
            let container = setupVisualContainer()
            let textEntity = createTextVisual(text: "⬆", size: 0.04, color: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), position: [0, 0.01, 0.06])
            textEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            container.addChild(textEntity)
            
            exerciseAnimTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
                guard let self = self, let wrapper = self.cosmonautEntity else { return }
                var t1 = wrapper.transform
                t1.translation.z = self.basePosition.z + 0.03
                t1.rotation = self.baseOrientation * simd_quatf(angle: .pi / 36, axis: [0, 1, 0]) // 5 derece Y
                wrapper.move(to: t1, relativeTo: wrapper.parent, duration: 0.6, timingFunction: .easeInOut)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    var t2 = wrapper.transform
                    t2.translation.z = self.basePosition.z - 0.01
                    t2.rotation = self.baseOrientation * simd_quatf(angle: -.pi / 36, axis: [0, 1, 0])
                    wrapper.move(to: t2, relativeTo: wrapper.parent, duration: 0.6, timingFunction: .easeInOut)
                }
            }
            exerciseAnimTimer?.fire()
        }
        
        // MARK: - Helpers
        private func applyMaterial(_ material: RealityKit.Material, to entity: Entity) {
            if let modelEntity = entity as? ModelEntity, var model = modelEntity.model {
                model.materials = model.materials.map { _ in material }
                modelEntity.model = model
            }
            for child in entity.children {
                applyMaterial(material, to: child)
            }
        }

        // MARK: - Medication Overlay Builder

        private func buildMedicationOverlay(on anchor: AnchorEntity) {
            let panelMesh = MeshResource.generatePlane(width: 0.18, depth: 0.08)
            var panelMat = UnlitMaterial()
            let bgColor: UIColor = hasPendingMedication
                ? UIColor(red: 0.90, green: 1.0, blue: 0.92, alpha: 0.95)
                : UIColor(red: 1.0, green: 0.92, blue: 0.92, alpha: 0.95)
            panelMat.color = .init(tint: bgColor)
            let panelEntity = ModelEntity(mesh: panelMesh, materials: [panelMat])
            panelEntity.position = [0, 0.001, -0.05]
            panelEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            anchor.addChild(panelEntity)

            let statusStr = hasPendingMedication
                ? "  ALINACAK ILAC MEVCUT"
                : "  TUM ILACLAR ALINDI"
            let statusColor: UIColor = hasPendingMedication
                ? UIColor(red: 0.10, green: 0.65, blue: 0.30, alpha: 1)
                : UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)

            let statusMesh = MeshResource.generateText(
                statusStr,
                extrusionDepth: 0.001,
                font: .boldSystemFont(ofSize: 0.012)
            )
            var statusMat = UnlitMaterial()
            statusMat.color = .init(tint: statusColor)
            let statusEntity = ModelEntity(mesh: statusMesh, materials: [statusMat])
            statusEntity.position = [-0.08, 0.002, -0.04]
            statusEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            anchor.addChild(statusEntity)
        }

        // MARK: - Float Animation (yukarı-aşağı hafif salınım)

        private func startFloatAnimation(for anchor: AnchorEntity) {
            var up = true
            var currentY: Float = 0
            floatTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak anchor] _ in
                guard let anchor = anchor else { return }
                let delta: Float = up ? 0.0003 : -0.0003
                currentY += delta
                anchor.position.y = currentY
                if currentY > 0.006 { up = false }
                if currentY < -0.006 { up = true }
            }
        }

        // MARK: - Pulse Animation

        private func animatePulse(entity: ModelEntity) {
            var growing = true
            Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak entity] timer in
                guard let entity = entity else { timer.invalidate(); return }
                let delta: Float = growing ? 0.008 : -0.008
                let newScale = entity.scale.x + delta
                entity.scale = [newScale, newScale, newScale]
                if newScale > 1.4 { growing = false }
                if newScale < 0.8 { growing = true }
            }
        }
    }
}
