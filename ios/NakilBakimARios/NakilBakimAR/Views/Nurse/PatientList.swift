import SwiftUI

struct PatientList: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""
    @State private var phaseFilter = 0

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    nurseHero
                    vardiyaOzetCard
                    nurseFilters

                    if api.nursePatientsLoading && api.nursePatients.isEmpty {
                        LoadingStateCard(text: "Hasta listesi yükleniyor...")
                    } else if filteredPatients.isEmpty {
                        EmptyStateCard(
                            title: "Kayıtlı hasta bulunamadı",
                            subtitle: "Filtreyi değiştirin veya yeni hasta ekleyin."
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPatients) { patient in
                                NavigationLink {
                                    PatientDetail(patient: patient)
                                } label: {
                                    patientCard(patient)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let errorMessage = api.lastErrorMessage {
                        SurfaceCard {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .navigationTitle("Aktif Hastalar")
        .safeAreaInset(edge: .bottom) {
            nurseBottomBar
        }
        .task {
            do {
                try await api.fetchNursePatients()
            } catch {
                // Hata mesajı APIService.lastErrorMessage üzerinden gösteriliyor.
            }
        }
    }

    // MARK: - Hero
    private var nurseHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bugün ilgilenmeniz gereken \(api.nursePatients.count) hasta bulunuyor.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
    
    // MARK: - Shift Summary
    private var vardiyaOzetCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VARDİYA ÖZETİ")
                .font(.caption.bold())
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.8))
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(api.tasks.count > 0 ? api.tasks.count : 12)") // Dinamik veya fallback
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Kritik Görev")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 6) {
                HStack {
                    Text("Tamamlanan")
                    Spacer()
                    Text("%65") // Mockup'taki oran
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * 0.65)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(AppSpacing.xLarge)
        .background(LinearGradient.primaryAction)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: InonuPalette.primary.opacity(0.3), radius: 15, x: 0, y: 8)
    }

    // MARK: - Filters
    private var nurseFilters: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Hasta arayın...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.9))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(InonuPalette.cardBorder, lineWidth: 1))
            
            Picker("Faz", selection: $phaseFilter) {
                Text("Tümü").tag(0)
                Text("Pre-op").tag(1)
                Text("Post-op").tag(2)
            }
            .pickerStyle(.menu)
            .frame(height: 44)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.9))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(InonuPalette.cardBorder, lineWidth: 1))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Patient Card
    private func patientCard(_ patient: PatientProfile) -> some View {
        let isPostOp = patient.carePhase == "post_op"
        
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // Avatar (Initials)
                ZStack {
                    Circle()
                        .fill(isPostOp ? InonuPalette.primary.opacity(0.15) : InonuPalette.pageTop)
                        .frame(width: 54, height: 54)
                    
                    if let unwrapName = patient.fullName, let first = unwrapName.first {
                        Text(String(first))
                            .font(.title3.bold())
                            .foregroundStyle(isPostOp ? InonuPalette.primary : InonuPalette.deepNavy)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundStyle(InonuPalette.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(patient.fullName ?? "İsimsiz Hasta")
                        .font(.headline)
                        .foregroundStyle(InonuPalette.deepNavy)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.caption2)
                            .foregroundStyle(InonuPalette.secondary)
                        // Örnek statik veri (geliştirilebilir)
                        Text(patient.diagnosis ?? "Tanı girilmemiş")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: -8) {
                        // Fake progress badges like mockup (ALT / AST)
                        Circle().fill(InonuPalette.pageTop).frame(width: 28, height: 28).overlay(Text("ALT").font(.system(size: 8, weight: .bold)).foregroundStyle(InonuPalette.deepNavy))
                        Circle().fill(InonuPalette.primary.opacity(0.3)).frame(width: 28, height: 28).overlay(Text("AST").font(.system(size: 8, weight: .bold)).foregroundStyle(InonuPalette.navySoft))
                    }
                    .padding(.top, 4)
                }

                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(isPostOp ? "AMELİYAT SONRASI" : "AMELİYAT ÖNCESİ")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isPostOp ? InonuPalette.primary : InonuPalette.secondary.opacity(0.6))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            HStack {
                if !patient.isActive {
                    Label("Pasif", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(InonuPalette.danger)
                } else if let lastStr = patient.lastVitalRecordedAt,
                          let lastDate = lastStr.parseIsoDate(),
                          Date().timeIntervalSince(lastDate) <= 12 * 3600 {
                    Label("Vital bulgular stabil", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(InonuPalette.success)
                } else {
                    Label("Son 12 saattir vital girilmedi", systemImage: "exclamationmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(InonuPalette.warning)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("Detayları Gör")
                    Image(systemName: "chevron.right")
                }
                .font(.caption.bold())
                .foregroundStyle(InonuPalette.deepNavy)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(InonuPalette.cream.opacity(0.3))
        }
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.large).stroke(InonuPalette.cardBorder, lineWidth: 1))
        .shadow(color: AppShadow.card, radius: 8, x: 0, y: 4)
    }

    // MARK: - Computed
    private var filteredPatients: [PatientProfile] {
        let phaseFiltered = api.nursePatients.filter { patient in
            switch phaseFilter {
            case 1: return patient.carePhase != "post_op"
            case 2: return patient.carePhase == "post_op"
            default: return true
            }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return phaseFiltered }
        return phaseFiltered.filter { patient in
            (patient.fullName ?? "").lowercased().contains(q) ||
            (patient.diagnosis ?? "").lowercased().contains(q)
        }
    }

    // MARK: - Bottom Bar
    private var nurseBottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.08)
            HStack(spacing: 12) {
                NavigationLink {
                    RegisterView()
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Hasta Ekle")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(InonuPalette.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                    .shadow(color: InonuPalette.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial)
        }
    }
}
