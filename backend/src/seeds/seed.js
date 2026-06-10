/**
 * Sunum Seed Scripti — NakilBakımAR
 *
 * Yapılanlar:
 *  1. Tüm dinamik veriler temizlenir
 *  2. Korunan kullanıcılar yeniden oluşturulur (hemşire + birincil hasta)
 *  3. 5 demo hasta oluşturulur
 *  4. Her hastaya modüller, görevler ve vital bulgular atanır
 *  5. Senaryo logları eklenir
 *
 * Çalıştırma:
 *   DATABASE_URL="postgres://admin:12345@localhost:5432/nakilbakimar" node src/seeds/seed.js
 */

import bcrypt from "bcryptjs";
import { pool } from "../db/pool.js";

// ─── Yardımcılar ─────────────────────────────────────────────────────────────

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString();
}

function hoursAgo(n) {
  return new Date(Date.now() - n * 3600 * 1000).toISOString();
}

function hoursFromNow(n) {
  return new Date(Date.now() + n * 3600 * 1000).toISOString();
}

// ─── Sabit giriş bilgileri ────────────────────────────────────────────────────
const NURSE_EMAIL    = "nurse@nakil.com";
const NURSE_PASSWORD = "123456";
const NURSE_NAME     = "Hemşire Fatma Kılıç";

const PATIENT_TC    = "10000000146";
const PATIENT_PIN   = "1001";
const PATIENT_NAME  = "Ahmet Yılmaz";

// ─── Ana ─────────────────────────────────────────────────────────────────────

try {
  console.log("🚀  Sunum seed başlıyor...\n");

  // ── 1. Temizlik ─────────────────────────────────────────────────────────────
  console.log("🧹  Veritabanı temizleniyor...");

  // Sıralı silme (foreign key kısıtları nedeniyle)
  await pool.query("DELETE FROM scenario_logs");
  await pool.query("DELETE FROM notifications_log");
  await pool.query("DELETE FROM vital_signs");
  await pool.query("DELETE FROM tasks");
  await pool.query("DELETE FROM patient_modules");
  await pool.query("DELETE FROM patient_profiles");
  await pool.query("DELETE FROM ar_content");
  await pool.query("DELETE FROM users");
  await pool.query("DELETE FROM care_modules");

  console.log("   ✅  Temizlik tamamlandı.\n");

  // ── 2. care_modules ─────────────────────────────────────────────────────────
  await pool.query(`
    INSERT INTO care_modules (name)
    VALUES ('mobilization'), ('nutrition'), ('wound_care'), ('medication'), ('vital_signs')
    ON CONFLICT (name) DO NOTHING
  `);
  const modRes = await pool.query("SELECT id, name FROM care_modules ORDER BY id");
  const modMap = {};
  for (const row of modRes.rows) modMap[row.name] = row.id;

  // ── 3. Hemşire ──────────────────────────────────────────────────────────────
  console.log("👩‍⚕️  Hemşire oluşturuluyor...");
  const nurseHash = await bcrypt.hash(NURSE_PASSWORD, 10);
  const nurseRes = await pool.query(
    `INSERT INTO users (email, password_hash, full_name, role)
     VALUES ($1, $2, $3, 'nurse') RETURNING id`,
    [NURSE_EMAIL, nurseHash, NURSE_NAME]
  );
  const nurseId = nurseRes.rows[0].id;
  console.log(`   ✅  ${NURSE_NAME} (${NURSE_EMAIL})\n`);

  // ── 4. Birincil hasta (korunan giriş bilgileri) ──────────────────────────────
  console.log("🧑‍🤝‍🧑  Birincil hasta oluşturuluyor...");
  const patientPinHash = await bcrypt.hash(PATIENT_PIN, 10);
  const primaryPatientRes = await pool.query(
    `INSERT INTO users (email, password_hash, full_name, role, patient_tc, patient_pin_hash)
     VALUES ($1, $2, $3, 'patient', $4, $5) RETURNING id`,
    ["ahmet.yilmaz@nakil.com", nurseHash, PATIENT_NAME, PATIENT_TC, patientPinHash]
  );
  const primaryUserId = primaryPatientRes.rows[0].id;

  // Ameliyat tarihi: 5 gün önce → post_op
  const primaryProfileRes = await pool.query(
    `INSERT INTO patient_profiles (user_id, diagnosis, nurse_id, transplant_date, is_active)
     VALUES ($1, $2, $3, $4, true) RETURNING id`,
    [primaryUserId, "Karaciğer sirozu — Canlı donör karaciğer nakli", nurseId, daysAgo(5)]
  );
  const primaryProfileId = primaryProfileRes.rows[0].id;
  console.log(`   ✅  ${PATIENT_NAME} — TC: ${PATIENT_TC} / PIN: ${PATIENT_PIN}  (post-op, 5. gün)\n`);

  // ── 5. Demo Hastaları ────────────────────────────────────────────────────────
  console.log("👥  Demo hastaları oluşturuluyor...");

  // transplantDaysAgo: null → pre_op, sayı → post_op
  const demoPatients = [
    {
      name: "Zeynep Arslan",
      tc: "17050822454",
      pin: "1002",
      email: "zeynep.arslan@nakil.com",
      diagnosis: "Hepatosellüler karsinom — karaciğer nakli sonrası takip",
      transplantDaysAgo: 12,
      isActive: true,
    },
    {
      name: "Mehmet Öztürk",
      tc: "19044812574",
      pin: "1003",
      email: "mehmet.ozturk@nakil.com",
      diagnosis: "Primer biliyer siroz — cerrahi değerlendirme aşaması",
      transplantDaysAgo: null, // pre_op
      isActive: true,
    },
    {
      name: "Ayşe Demir",
      tc: "21038802694",
      pin: "1004",
      email: "ayse.demir@nakil.com",
      diagnosis: "Otoimmün hepatit — karaciğer nakli adayı",
      transplantDaysAgo: null, // pre_op
      isActive: true,
    },
    {
      name: "Hasan Çelik",
      tc: "23032792814",
      pin: "1005",
      email: "hasan.celik@nakil.com",
      diagnosis: "Karaciğer yetmezliği — uzun dönem cerrahi sonrası kontrol",
      transplantDaysAgo: 30,
      isActive: true,
    },
    {
      name: "Fatma Şahin",
      tc: "25026782934",
      pin: "1006",
      email: "fatma.sahin@nakil.com",
      diagnosis: "Wilson hastalığı — deşarj sonrası poliklinik takibi",
      transplantDaysAgo: 60,
      isActive: false, // Pasif
    },
  ];

  const profiles = [{ id: primaryProfileId, name: PATIENT_NAME, isActive: true }];

  for (const p of demoPatients) {
    const ph = await bcrypt.hash(p.pin, 10);
    const uRes = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role, patient_tc, patient_pin_hash)
       VALUES ($1,$2,$3,'patient',$4,$5) RETURNING id`,
      [p.email, nurseHash, p.name, p.tc, ph]
    );
    const txDate = p.transplantDaysAgo ? daysAgo(p.transplantDaysAgo) : null;
    const pRes = await pool.query(
      `INSERT INTO patient_profiles (user_id, diagnosis, nurse_id, transplant_date, is_active)
       VALUES ($1,$2,$3,$4,$5) RETURNING id`,
      [uRes.rows[0].id, p.diagnosis, nurseId, txDate, p.isActive]
    );
    profiles.push({ id: pRes.rows[0].id, name: p.name, isActive: p.isActive, transplantDaysAgo: p.transplantDaysAgo });
    const phase = p.transplantDaysAgo ? "post-op" : "pre-op";
    console.log(`   ✅  ${p.name} — ${phase}${!p.isActive ? " (pasif)" : ""}`);
  }

  console.log("");

  // ── 6. Modüller ─────────────────────────────────────────────────────────────
  console.log("📦  Modüller atanıyor...");

  for (const prof of profiles) {
    if (!prof.isActive) continue;
    const isPostOp = prof.transplantDaysAgo != null;
    const modules = isPostOp
      ? ["mobilization", "nutrition", "wound_care", "medication", "vital_signs"]
      : ["nutrition", "medication", "vital_signs"];
    for (const mod of modules) {
      await pool.query(
        `INSERT INTO patient_modules (patient_id, module_id, is_enabled)
         VALUES ($1, $2, true) ON CONFLICT DO NOTHING`,
        [prof.id, modMap[mod]]
      );
    }
  }
  console.log("   ✅  Modüller atandı.\n");

  // ── 7. Vital Bulgular ────────────────────────────────────────────────────────
  console.log("💓  Vital bulgular ekleniyor...");

  async function addVital(pid, hoursBack, opts = {}) {
    await pool.query(
      `INSERT INTO vital_signs
         (patient_id, nurse_id, recorded_at, body_temperature,
          blood_pressure_systolic, blood_pressure_diastolic,
          heart_rate, oxygen_saturation, notes, shared_with_patient)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [
        pid, nurseId, hoursAgo(hoursBack),
        opts.temp    ?? 36.7,
        opts.bpSys   ?? 118,
        opts.bpDia   ?? 76,
        opts.hr      ?? 78,
        opts.spo2    ?? 98,
        opts.notes   ?? "Rutin vital kontrol — stabil",
        opts.shared  ?? true,
      ]
    );
  }

  // Ahmet Yılmaz (post-op 5. gün) — zengin vital geçmişi
  await addVital(primaryProfileId,  2,  { temp: 36.8, bpSys: 120, hr: 80, spo2: 98, notes: "Sabah kontrolü — normal sınırlarda" });
  await addVital(primaryProfileId,  8,  { temp: 37.1, bpSys: 125, hr: 84, spo2: 97, notes: "Akşam kontrolü — hafif ateş izlenecek" });
  await addVital(primaryProfileId,  26, { temp: 36.6, bpSys: 115, hr: 76, spo2: 99, notes: "Sabah kontrolü — stabil" });
  await addVital(primaryProfileId,  32, { temp: 36.9, bpSys: 122, hr: 82, spo2: 98 });
  await addVital(primaryProfileId,  50, { temp: 37.3, bpSys: 130, hr: 90, spo2: 96, notes: "Ateş yüksekliği — doktor bilgilendirildi" });
  await addVital(primaryProfileId,  74, { temp: 36.7, bpSys: 118, hr: 78, spo2: 98 });
  await addVital(primaryProfileId,  98, { temp: 36.5, bpSys: 116, hr: 75, spo2: 99 });
  await addVital(primaryProfileId, 122, { temp: 36.8, bpSys: 119, hr: 79, spo2: 98 });

  // Zeynep Arslan (post-op 12. gün)
  const zeynepId = profiles[1].id;
  await addVital(zeynepId, 3,   { temp: 36.9, bpSys: 122, hr: 82, spo2: 97 });
  await addVital(zeynepId, 27,  { temp: 37.0, bpSys: 128, hr: 86, spo2: 97 });
  await addVital(zeynepId, 51,  { temp: 36.7, bpSys: 119, hr: 79, spo2: 98 });

  // Hasan Çelik (post-op 30. gün)
  const hasanId = profiles[4].id;
  await addVital(hasanId, 5,   { temp: 36.6, bpSys: 117, hr: 74, spo2: 99 });
  await addVital(hasanId, 53,  { temp: 36.8, bpSys: 121, hr: 80, spo2: 98 });
  await addVital(hasanId, 101, { temp: 37.0, bpSys: 126, hr: 85, spo2: 97 });

  // Mehmet & Ayşe → vital kaydı YOK (kasıtlı — hemşire bildirim uyarısı için)
  console.log("   ✅  Vital kayıtlar eklendi. (Mehmet & Ayşe kasıtlı boş — bildirim testi)\n");

  // ── 8. Görevler ─────────────────────────────────────────────────────────────
  console.log("📋  Görevler oluşturuluyor...");

  async function addTask(pid, type, title, desc, scheduledHoursFromNow, completed = false) {
    const scheduledAt = scheduledHoursFromNow != null ? hoursFromNow(scheduledHoursFromNow) : null;
    const completedAt = completed ? new Date().toISOString() : null;
    await pool.query(
      `INSERT INTO tasks
         (patient_id, assigned_by, type, title, description, scheduled_time, is_completed, completed_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [pid, nurseId, type, title, desc, scheduledAt, completed, completedAt]
    );
  }

  // ── Ahmet Yılmaz — post-op 5. gün (tam set)
  await addTask(primaryProfileId, "medication",
    "Sabah dozu: Takrolimus (FK506)",
    "Sabah aç karnına Takrolimus alınacak. Greyfurt suyu ile alınmaması gerekir. Düzenli kan düzeyi takibi yapılacak.",
    1);
  await addTask(primaryProfileId, "medication",
    "Öğle dozu: Mikofenolat Mofetil",
    "Öğle yemeğiyle birlikte Mikofenolat Mofetil alınacak. Mide bulantısı durumunda hemşireye bildirin.",
    5);
  await addTask(primaryProfileId, "medication",
    "Akşam dozu: Prednizon",
    "Akşam yemeği ile birlikte Prednizon alınacak. Kan şekeri izlemi kritiktir.",
    10, true);

  await addTask(primaryProfileId, "exercise",
    "10 dk yürüyüş",
    "Koridorda yavaş tempolu 10 dakikalık yürüyüş. Nefes darlığı hissedilirse durunuz.",
    2);
  await addTask(primaryProfileId, "exercise",
    "Derin nefes egzersizi",
    "Yatakta 10 tekrar derin nefes alma-verme egzersizi. Her nefes 4 saniye tutulacak.",
    3, true);

  await addTask(primaryProfileId, "nutrition",
    "Düşük tuzlu öğün takibi",
    "Günlük tuz alımı 2 gr ile sınırlandırılacak. İşlenmiş gıda ve hazır çorba tüketiminden kaçınılacak.",
    4);
  await addTask(primaryProfileId, "nutrition",
    "Sıvı alımı takibi",
    "Günlük sıvı alımı 1.5-2 litre ile sınırlandırılacak. Bardak sayısı kaydedilecek.",
    6, true);

  await addTask(primaryProfileId, "wound_care",
    "Steril pansuman değişimi",
    "Karın bölgesi ameliyat yarası steril teknikle temizlenecek ve yeni pansuman uygulanacak. Enfeksiyon belirtileri not edilecek.",
    8);
  await addTask(primaryProfileId, "wound_care",
    "Yara yeri enfeksiyon kontrolü",
    "Ameliyat bölgesinde kızarıklık, ısı artışı, akıntı veya şişlik değerlendirilecek.",
    9, true);

  // ── Zeynep Arslan — post-op 12. gün
  await addTask(zeynepId, "medication",
    "Sabah dozu: Takrolimus",
    "Takrolimus kan düzeyi normal sınırlarda. Dozun devamı planlandı.",
    2);
  await addTask(zeynepId, "exercise",
    "Ayak bileği rotasyonu",
    "Pulmoner emboli riskini azaltmak için her iki ayak bileğini 10'ar kez çeviriniz.",
    3, true);
  await addTask(zeynepId, "wound_care",
    "Dren takibi ve boşaltma",
    "Jackson-Pratt dreninin içeriği ve miktarı değerlendirilecek. Günlük drenaj miktarı kaydedilecek.",
    5);

  // ── Mehmet Öztürk — pre-op
  const mehmetId = profiles[2].id;
  await addTask(mehmetId, "medication",
    "Karaciğer koruyucu ilaç",
    "Ursodeoksikolik asit sabah aç karnına alınacak. Karaciğer enzim değerleri izlenecek.",
    2);
  await addTask(mehmetId, "nutrition",
    "Protein takviyesi",
    "Her öğünde yeterli protein alımı sağlanacak. Günlük hedef: vücut ağırlığının 1.2 katı gram.",
    6);

  // ── Ayşe Demir — pre-op
  const ayseId = profiles[3].id;
  await addTask(ayseId, "medication",
    "İmmünosupresif başlangıç dozu",
    "Transplant öncesi immünosupresif protokol başlatıldı. Düzenli kan testleri yapılacak.",
    4);
  await addTask(ayseId, "nutrition",
    "Şeker kısıtlı diyet",
    "Steroid tedavisine bağlı hiperglisemi riski nedeniyle şekerli içecek ve tatlılardan kaçınılacak.",
    8);

  // ── Hasan Çelik — post-op 30. gün
  await addTask(hasanId, "medication",
    "Takrolimus — azaltılmış doz protokolü",
    "Kan düzeyi stabil seyirde. Cerrah onayıyla doz azaltma protokolü başlatıldı.",
    2, true);
  await addTask(hasanId, "exercise",
    "Otur-kalk egzersizi",
    "Hemşire gözetiminde yataktan kalkıp sandalyeye oturma. 3 tekrar yapılacak.",
    4);

  console.log("   ✅  Görevler oluşturuldu.\n");

  // ── 9. Senaryo Logları ───────────────────────────────────────────────────────
  console.log("🎯  Senaryo logları ekleniyor...");

  const scenarios = [
    { key: "medication_timing",    decision: "takrolimus_timing",   option: "empty_stomach", correct: true,  dur: 45 },
    { key: "wound_assessment",     decision: "redness_action",      option: "notify_nurse",  correct: true,  dur: 62 },
    { key: "diet_plan",            decision: "salt_limit",          option: "2g_daily",      correct: true,  dur: 38 },
    { key: "vital_interpretation", decision: "fever_action",        option: "wait_monitor",  correct: false, dur: 55 },
    { key: "exercise_safety",      decision: "breathlessness",      option: "stop_exercise", correct: true,  dur: 40 },
    { key: "drain_management",     decision: "drain_output",        option: "record_notify", correct: true,  dur: 70 },
  ];

  for (const s of scenarios) {
    await pool.query(
      `INSERT INTO scenario_logs
         (patient_id, scenario_key, decision_key, selected_option, was_correct, module_duration_sec)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [primaryProfileId, s.key, s.decision, s.option, s.correct, s.dur]
    );
  }
  console.log("   ✅  Senaryo logları eklendi.\n");

  // ── 10. AR İçerik ───────────────────────────────────────────────────────────
  await pool.query(`
    INSERT INTO ar_content (marker_image_url, model_url, animation_type, task_type) VALUES
      ('marker_mobilization_v1', 'https://example.com/models/walk.usdz', 'pose', 'exercise'),
      ('marker_medication_v1', 'https://example.com/models/pill.usdz', 'info', 'medication'),
      ('marker_wound_v1', 'https://example.com/models/wound.usdz', 'guide', 'wound_care')
    ON CONFLICT DO NOTHING
  `);

  // ── Özet ────────────────────────────────────────────────────────────────────
  console.log("═══════════════════════════════════════════════════════");
  console.log("✅  SUNUM SEED TAMAMLANDI");
  console.log("═══════════════════════════════════════════════════════\n");
  console.log("🔑  GİRİŞ BİLGİLERİ:");
  console.log(`   Hemşire : ${NURSE_EMAIL}  /  Şifre: ${NURSE_PASSWORD}`);
  console.log(`   Hasta   : TC ${PATIENT_TC}  /  PIN: ${PATIENT_PIN}\n`);

  console.log("👥  HASTA ÖZETİ (Hemşire Paneli):");
  const summary = await pool.query(`
    SELECT u.full_name,
           CASE WHEN pp.transplant_date IS NOT NULL AND pp.transplant_date <= NOW()
             THEN 'Post-op' ELSE 'Pre-op' END AS phase,
           pp.is_active,
           (SELECT COUNT(*) FROM tasks t WHERE t.patient_id = pp.id) AS task_count,
           (SELECT COUNT(*) FROM vital_signs v WHERE v.patient_id = pp.id) AS vital_count,
           (SELECT MAX(recorded_at) FROM vital_signs v WHERE v.patient_id = pp.id) AS last_vital
    FROM patient_profiles pp
    JOIN users u ON u.id = pp.user_id
    ORDER BY pp.is_active DESC, u.full_name
  `);
  for (const r of summary.rows) {
    const status  = r.is_active ? "✅ Aktif" : "⛔ Pasif";
    const lastV   = r.last_vital
      ? `${Math.floor((Date.now() - new Date(r.last_vital).getTime()) / 3600000)}s önce`
      : "⚠️  KAYIT YOK";
    console.log(`   ${status}  ${r.full_name.padEnd(22)} ${r.phase.padEnd(8)} | ${String(r.task_count).padStart(2)} görev | ${String(r.vital_count).padStart(2)} vital | Son vital: ${lastV}`);
  }
  console.log("");

} catch (err) {
  console.error("❌  SEED HATASI:", err.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
