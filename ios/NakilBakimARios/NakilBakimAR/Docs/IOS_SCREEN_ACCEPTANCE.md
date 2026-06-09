# iOS Screen Map and Acceptance

## Screen Mapping (Stitch -> iOS)

| Stitch Screen | iOS Screen | Status |
| --- | --- | --- |
| giris_ekran_tr | Views/Authentication/LoginView.swift | done |
| giris_ekran_tr (register flow support) | Views/Authentication/RegisterView.swift | done |
| hasta_ana_paneli_tr | Views/Patient/DashboardView.swift | done |
| egzersiz_modulu_guncel_navigasyon | Views/Patient/ExerciseModuleView.swift | done |
| ilac module visuals | Views/Patient/MedicationModuleView.swift | done |
| beslenme visuals | Views/Patient/NutritionModuleView.swift | done |
| ar experience | Views/Patient/ARExperienceView.swift | done |
| hemsire_ana_paneli_tr | Views/Nurse/PatientList.swift | done |
| hasta_detay_hemsire_tr | Views/Nurse/PatientDetail.swift | done |
| gorev modal | Views/Nurse/AddTaskView.swift | done |
| vital modal | Views/Nurse/AddVitalView.swift | done |

## Role and Flow Rules

- Login uses role-based routing:
  - nurse -> nurse screens
  - patient -> patient screens
- Patient module visibility depends on nurse module toggles.
- Patient vitals list shows only shared records (backend filter).
- Nurse can toggle shared status for vitals from patient detail.
- Task completion uses one-way completion behavior in UI.

## Screen-level Acceptance Checklist

- Authentication
  - Login and Register use shared premium UI components.
  - Register screen is production-ready and no longer empty.
- Nurse flow
  - Patient list supports add-patient action and summary cards.
  - Patient detail shows segmented task timeline.
  - Vital list supports share/hide and delete actions.
- Patient flow
  - Dashboard includes reminders and weekly trend card.
  - Exercise, medication, nutrition screens have hero + quick actions.
  - AR screen includes marker status and decision actions.
- Shared components
  - Buttons, cards, headers, tab bar and token usage are unified.

