# BuildLedger – Personal Construction Manager

A production-ready Flutter application to track all expenses involved in building a house: materials, labour, payments, with automatic totals, reports, and cost prediction.

## Tech Stack

- **Flutter** (latest stable) + **Dart**
- **GetX** – state management, navigation, dependency injection
- **Firebase Firestore** – database
- **Firebase Storage** – bill images
- **Material 3** – UI
- **Clean Architecture** – core / data / domain / presentation
- **Repository pattern** – datasources + repositories

## Features

- **Materials** – Categories (Foundation, Brick, Cement, Sand, Steel, Slab, Plaster, Flooring, Doors, Windows, Other). Track quantity, unit, price, supplier, date, bill image.
- **Labour** – Types (Mason, Bricklayer, Helper, Painter, Carpenter, Electrician, Plumber). Hourly or fixed-day rate, work hours, total payment.
- **Payments** – Person (labour/supplier/contractor), total/paid/pending, status (paid/partial/pending).
- **Dashboard** – Animated summary cards, Material vs Labour chart, category breakdown, recent lists.
- **Reports** – Total/material/labour/paid/pending, category-wise expense, pie chart.
- **AI Prediction** – Predict future cost from previous cost and growth rate (structure ready for OpenAI).

## Project Structure

```
lib/
├── core/
│   ├── constants/       # app_constants, app_colors, app_strings, app_theme
│   ├── extensions/      # context, num
│   └── helper_functions # calculation_helpers, format_helpers, date_helpers
├── data/
│   ├── models/          # MaterialModel, LabourModel, PaymentModel
│   ├── repositories/    # MaterialRepository, LabourRepository, PaymentRepository
│   └── datasources/     # FirestoreDatasource, StorageDatasource
├── domain/
│   ├── entities/        # DashboardSummaryEntity
│   └── usecases/        # GetDashboardSummaryUseCase, PredictFutureCostUseCase
├── modules/
│   ├── dashboard_module/
│   ├── materials_module/
│   ├── labour_module/
│   ├── payments_module/
│   ├── reports_module/
│   └── ai_prediction_module/
├── presentation/
│   ├── widgets/         # AnimatedCounter, EmptyStateWidget, AnimatedCard
│   ├── animations/      # page_transitions
│   └── shell/           # MainShellView, MainBinding (bottom nav)
└── routes/              # app_routes, app_pages
```

## Setup

### 1. Clone and dependencies

```bash
cd personal_construction_manager
flutter pub get
```

### 2. Firebase (required for data and bill storage)

1. Create a project in [Firebase Console](https://console.firebase.google.com).
2. Add Android app: register with package name `com.example.personal_construction_manager` (or your package name), download `google-services.json` and place it in `android/app/`.
3. Add iOS app: register, download `GoogleService-Info.plist` and add it to `ios/Runner/` in Xcode.
4. Enable **Firestore Database** and **Storage** in the Firebase console.
5. (Optional) Create Firestore indexes if you use category/date filters; the app will suggest index links in debug console when needed.

### 3. Run

```bash
flutter run
```

## Important

- **No authentication** – single-user app. Data is stored under a fixed user id (`default_user`). Change `AppConstants.userId` if you need a different scope.
- **Bill images** – stored in Firebase Storage at `users/default_user/bills/`.
- **Export PDF** – Reports screen has an “Export PDF” action; wire it to the `printing` package and your report layout as needed.
- **Offline** – Firestore supports offline persistence; enable it in your Firebase init if needed.

## Helper APIs

- `CalculationHelpers.calculateMaterialCost(quantity, pricePerUnit)`
- `CalculationHelpers.calculateLabourHourly(hours, rate)` / `calculateLabourFixed(rate)`
- `CalculationHelpers.calculatePendingAmount(total, paid)`
- `CalculationHelpers.predictFutureCost(previousCost, growthRatePercent)`
- `FormatHelpers.formatCurrency(amount)` / `formatCurrencyCompact(amount)`
- `DateHelpers.formatDate(date)` / `toFirestoreDate(date)` / `parseDate(value)`

## License

Private / personal use.
