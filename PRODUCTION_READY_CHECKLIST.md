# Production Ready Checklist – BuildLedger

Construction Management Application. Tech stack: Flutter, Dart, GetX, Firebase Firestore.

---

## 1. Module summary

| Module | Route | Purpose |
|--------|--------|--------|
| **Main shell** | `/` | Two-tab layout: Dashboard + Menu. |
| **Dashboard** | `/dashboard` | Realtime stats (workers, attendance today, labour cost, material cost, payments made, pending). Charts: Material vs Labour, Labour Cost by day, Material Cost by category, Attendance by day. Filter: Today / This Week / This Month. |
| **Workers (Labour)** | `/labour`, `/labour/form` | Worker list and add/edit. Hourly or daily rate. |
| **Materials** | `/materials`, `/materials/form` | Material list and add/edit. Category, quantity, unit, price. Cost = quantity × pricePerUnit. |
| **Attendance** | `/attendance` | Day-wise attendance. Mark Present (with hours, overtime) or Absent. Worker moves from Pending to Present/Absent. |
| **Worker Payments** | `/worker-payments` | Pay workers. Realtime pending (earnings − paid). Payment history, Pay Now dialog. |
| **Settings** | `/settings` | App settings. |
| **AI Prediction** | `/ai-prediction` | Cost prediction (optional). |

**Removed:** Old “Payments” module (`/payments`) and Reports module (`/reports`). Only **Worker Payment** handles payments. Reports-style totals live on the Dashboard.

---

## 2. Firestore structure

- **Base path:** `users/{userId}/` (e.g. `default_user`).
- **Collections:**
  - `materials` – name, category, quantity, unitType, pricePerUnit, totalPrice, purchaseDate, etc.
  - `labour` – workers: name, labourType, paymentMode, hourlyRate, fixedDayRate, totalPayment, etc.
  - `attendance` – workerId, date (yyyy-MM-dd), hoursWorked, overtimeHours, attendanceType, attendanceStatus (present/absent), overtimeEnabled, overtimeAmount.
  - `worker_payments` – workerId, amountPaid, paymentDate, paymentType, notes.

**Indexes (for streams):**  
Attendance: `date`, `workerId`+`date`. Worker payments: `workerId`+`paymentDate`, `paymentDate`. Materials/Labour: `createdAt` (or equivalent) for list queries.

---

## 3. Realtime architecture

- **Dashboard:** Subscribes to Firestore streams: workers, attendance (today + period), materials, worker payments. On any change, reactive lists update and `DashboardCalculationService` recomputes all stats. No manual refresh.
- **Worker Payment screen:** Streams workers, attendance (for earnings), and worker payments. Pending = earnings − total paid; updates as soon as a payment is added.
- **Attendance:** Streams workers and attendance for the selected date. Marking attendance updates the stream; worker disappears from Pending.
- **Materials / Workers:** List screens use repository streams where available for live updates.

---

## 4. Edge case handling

- **Firestore/network errors:** Stream `onError` sets an error state; UI shows message + Retry (e.g. Dashboard). No uncaught crash.
- **Null / missing data:** Calculation service and UI use null-safe defaults (0, empty list, “—”). Worker lookup by id uses `firstOrNull`; missing worker skips that record in labour cost.
- **Invalid input:** Validation in forms (amounts > 0, required fields). Pay Now validates amount ≤ pending.
- **Empty collections:** Lists show empty state (“Tap + to add”) instead of blank or error.

---

## 5. Test coverage

- **Unit:**  
  - `dashboard_calculation_service_test.dart` – total workers, present/absent, hours, labour cost (today + by day), material cost, payments made, pending, category map, labour cost by day, attendance by day.  
  - `payment_calculator_test.dart` – hourly/daily labour cost, overtime, half day, absent.  
  - `dashboard_controller_test.dart` – stats recompute when streams emit, filter, refreshStreams (with fakes, no Firebase).  
  - `worker_payment_controller_test.dart` – payment aggregation, pending.  
  - `attendance_controller_test.dart` – validation, marking.  
- **Widget:**  
  - `dashboard_view_test.dart` – app bar, filter chips, section titles (incl. Recent Worker Payments), SummaryCard.  
  - `worker_payment_view_test.dart`, `attendance_view_test.dart` – screen structure and key elements.

---

## 6. Routes (production)

Only these routes are registered:

- `/` – Main shell (Dashboard + Menu)
- `/dashboard` – Dashboard
- `/materials`, `/materials/form` – Materials
- `/labour`, `/labour/form` – Workers
- `/attendance` – Attendance
- `/worker-payments` – Worker Payments
- `/ai-prediction` – AI Prediction
- `/settings` – Settings

No `/payments` or `/reports`. GetX navigation should not reference removed routes.

---

## 7. Worker payment logic

- **Earnings from attendance:**  
  - Hourly: `hoursWorked × hourlyRate` + overtime (hours × rate or fixed amount).  
  - Daily: fullDay → dailyRate, halfDay → dailyRate/2, absent/leave → 0; overtime added.  
  Implemented in `PaymentCalculator.paymentForAttendance`.
- **Pending:** `totalEarnings(from attendance) − totalPaid(worker_payments)`.
- **Total paid:** Sum of `amountPaid` in `worker_payments` for the worker (or globally for dashboard).

---

## 8. Material cost

- **Per item:** `quantity × pricePerUnit` (stored as `totalPrice`).
- **Total material cost:** Sum of `material.totalPrice` over all materials.
- **Units:** kg, litre, ton, piece, bag, etc. do not change the formula; they only describe the quantity.

---

## 9. Logging

- **AppLogger:** `api`, `db`, `form`, `calc`, `nav`, `error` for structured logs.
- **Dashboard:** `debugPrint` + AppLogger for “Dashboard updated”, workers count, present today, labour cost today.
- **Firestore:** Log on add/update/delete (e.g. “Attendance marked”, “Worker payment added”).

---

## 10. Performance

- Use **streams** instead of repeated one-off fetches where possible (dashboard, worker payments, attendance).
- Use **limited and filtered** Firestore queries (limit, date range, workerId).
- Avoid loading full collections; use indexed fields for filters.

---

This checklist reflects the current production-ready state after removing the old Payments and Reports modules and keeping only Worker Payment and the realtime Dashboard.
