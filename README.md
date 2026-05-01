# Odlikas Ekran

Flutter aplikacija za tablet/ekran za studente Tehničkog veleučilišta u Zagrebu (TVZ) koja se sparuje s mobilnom aplikacijom Odlikas putem QR koda i pruža prošireno sučelje na drugom zaslonu — optimizirano za landscape format.

## Funkcionalnosti

- **Ocjene** — pregled trenutnih ocjena po predmetu s detaljnim tablicama vrednovanja i grafičkim prikazom
- **Kalendar** — osobni kalendar s prikazom nadolazećih rokova i mogućnošću kreiranja događaja
- **MathNotes** — digitalna ploča za crtanje i pisanje matematičkih zadataka s AI rješavanjem (DeepSeek + Mathpix OCR), undo/redo, oblicima, tekstom i uvozom slika; bilješke se automatski spremaju u galeriju
- **Pomodoro** — ugrađeni Pomodoro tajmer (25/5/15 min) s praćenjem sesija i niza dana putem backend API-ja, dnevni limit od 8 sesija i optimistično ažuriranje
- **Obaveze** — popis zadataka s dodavanjem i praćenjem statusa
- **Datoteke** — pregled i odabir stranica PDF materijala

## Sparivanje s mobilnom aplikacijom

Ekran prikazuje QR kod koji student skenira mobilnom aplikacijom. Nakon skeniranja, ekran dobiva Bearer token koji se pohranjuje u Hive i koristi za sve daljnje API pozive prema Odlikas backendu.

## Tehnologije

| Sloj | Tehnologija |
|---|---|
| UI | Flutter (Dart), landscape način rada |
| Upravljanje stanjem | Provider + ChangeNotifier |
| REST API | `http` paket s Bearer token autentifikacijom (token iz Hive) |
| Autentifikacija | QR kod sparivanje → JWT token pohranjen u Hive |
| AI (MathNotes) | DeepSeek API (rješavanje zadataka) + Mathpix (OCR) |
| Baza podataka u oblaku | Cloud Firestore |
| Lokalna pohrana | Hive |
| Animacije | Lottie |
| Sučelje | Google Fonts, flutter_svg, flutter_math_fork, LaTeX prikaz |

## Struktura projekta

```
lib/
├── main.dart                        # Ulazna točka, routing, MultiProvider setup
├── responsive.dart                  # Pomoćne klase za responzivnost
├── custom_adapters.dart             # Hive adapteri (WhiteboardData, Uint8List)
├── exceptions/
│   └── app_exceptions.dart          # Tipizirana klasa ApiException
├── models/
│   ├── grades.dart                  # Modeli ocjena i predmeta
│   ├── specific_subject.dart        # Detalji specifičnog predmeta
│   ├── student_profile.dart         # Profil studenta
│   ├── task.dart                    # Model zadatka (ToDoList)
│   └── tests.dart                   # Model testova i rokova
├── viewmodels/
│   ├── viewmodel.dart               # HomePageViewModel (ocjene, profil)
│   └── test_viewmodel.dart          # TestViewmodel (testovi)
├── database/
│   ├── api/
│   │   ├── api_service.dart         # HTTP servis (ocjene, profil, testovi)
│   │   ├── pomodoro_api_service.dart # Pomodoro API (GetStreak, CompleteSession)
│   │   ├── deepseek_service.dart    # DeepSeek AI servis
│   │   └── matpix_ai_solving.dart   # Mathpix OCR servis
│   ├── firebase_pomodoro_service.dart # Firestore Pomodoro sinkronizacija
│   ├── task_service.dart            # Firestore servis za zadatke
│   └── firebase_options.dart
└── pages/
    ├── SetupPage/                   # Početno postavljanje ekrana
    ├── QRCodePage/                  # QR kod za sparivanje s mobilnom aplikacijom
    ├── HomePage/                    # Glavna nadzorna ploča (4 kvadranta)
    │   └── widgets/
    │       └── grade_wheel.dart     # Grafički prikaz ocjene
    ├── Grades/                      # Popis ocjena po predmetima
    ├── SpecificSubject/             # Detalji predmeta, tablice i bilješke
    ├── Calendar/                    # Kalendar s događajima
    ├── ToDoList/                    # Popis obaveza
    ├── PomodoroTimer/               # Pomodoro tajmer
    │   ├── pomodoro_notifier.dart   # Stanje tajmera (ChangeNotifier)
    │   ├── pomodoro_timer_page.dart # UI stranica
    │   └── widgets/
    │       ├── pomodoro_container.dart  # Tajmer prikaz i gumbi
    │       └── session_circles.dart    # 8 krugova dnevnih sesija
    ├── MathNotes/                   # AI matematička ploča
    │   ├── math_notes.dart          # Glavna ploča
    │   ├── Core/                    # Tipovi i stanje ploče
    │   ├── Managers/                # Crtanje, tekst, slike, oblici, AI, pohrana
    │   ├── Shapes/                  # Oblici i painter klase
    │   ├── TextAdding/              # Dodavanje teksta
    │   ├── ImagesAdding/            # Dodavanje slika
    │   ├── saveWhiteboards/         # Hive pohrana i galerija bilješki
    │   └── widgets/                 # Alatna traka i UI komponente
    ├── SimilarTasks/                # Prikaz sličnih zadataka
    ├── SolutionStepsPage/           # Koraci rješenja AI zadataka
    └── UploadFiles/                 # Pregled i odabir stranica PDF-a
```

## Pokretanje projekta

### Preduvjeti

- Flutter SDK `^3.5.3`
- Dart SDK `^3.5.3`
- Android Studio ili VS Code s Flutter ekstenzijom
- Android tablet ili emulator
- Pristup Odlikas backend API-ju
- Mobilna aplikacija Odlikas za sparivanje

### Postavljanje

1. **Kloniranje repozitorija**
   ```bash
   git clone <repo-url>
   cd odlikas_ekran
   ```

2. **Instalacija ovisnosti**
   ```bash
   flutter pub get
   ```

3. **Konfiguracija varijabli okoline**

   Kreiraj `.env` datoteku u korijenu projekta (pored `pubspec.yaml`):
   ```env
   API_BASE_URL=http://<ip-adresa-backenda>:<port>
   DEEPSEEK_API_KEY=tvoj_deepseek_api_kljuc
   MATHPIX_APP_ID=tvoj_mathpix_app_id
   MATHPIX_APP_KEY=tvoj_mathpix_app_key
   ```

   > `.env` datoteka je navedena u `.gitignore` i **nikada se ne smije commitati**.

4. **Postavljanje Firebasea**

   Datoteka `google-services.json` (Android) potrebna je za Firebase funkcionalnosti. Kontaktiraj člana tima — nije pohranjena u repozitoriju.

5. **Pokretanje aplikacije**
   ```bash
   flutter run
   ```

   Aplikacija se automatski postavlja u landscape način rada i skriva sistemsku traku (immersive sticky).

### Pokretanje testova

```bash
flutter test
```

### Statička analiza koda

```bash
flutter analyze
```

## Tok autentifikacije

1. Ekran generira i prikazuje QR kod koji sadrži jedinstveni `screenId`
2. Student skenira QR kod mobilnom aplikacijom Odlikas
3. Backend veže `screenId` uz studentov račun i vraća Bearer token
4. Token se pohranjuje u Hive (`user_credentials` box, ključ `token`)
5. Svi daljnji API pozivi (`ApiService`, `PomodoroApiService`) automatski čitaju token iz Hive i dodaju ga u `Authorization: Bearer` zaglavlje

## Varijable okoline

| Varijabla | Opis |
|---|---|
| `API_BASE_URL` | Osnovna URL adresa Odlikas ASP.NET backend API-ja |
| `DEEPSEEK_API_KEY` | DeepSeek API ključ za AI rješavanje matematičkih zadataka |
| `MATHPIX_APP_ID` | Mathpix App ID za OCR prepoznavanje matematičkih izraza |
| `MATHPIX_APP_KEY` | Mathpix App Key za OCR prepoznavanje matematičkih izraza |

Osjetljive vrijednosti nikada nisu hardkodirane. Sve tajne učitavaju se iz `.env` datoteke pri pokretanju.

## Doprinos projektu

1. Odvoji granu od `main` za nove značajke: `git checkout -b feature/naziv-znacajke`
2. Koristi konvencionalne commit poruke: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
3. Otvori pull request prema `main`

## Tim

Razvija tim **Odlikas** za Mc2 natjecanje.
