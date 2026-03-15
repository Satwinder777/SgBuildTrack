# Realtime Dashboard Architecture

This document describes the data flow, stream architecture, calculation logic, and performance strategy for the Construction Management dashboard.

## 1. Dashboard goal

The dashboard **reads only** from existing modules (Worker, Attendance, Payment, Material). It does not write to them. Any change in:

- **Attendance** (new/edit) → updates present/absent counts, today’s hours, today’s labour cost, and (via total labour earnings) pending payments.
- **Worker payments** (new) → updates total payments made and pending payments.
- **Materials** (add/update/cost change) → updates total material cost and category breakdown.

The dashboard does not use the old “Payments” module (removed). Only **Worker Payment** module is used. The user never has to refresh; all stats update in realtime via Firestore streams and GetX reactive state.

---

## 2. Data flow (high level)

```
Firestore collections
    → Repository streams (streamWorkers, streamAttendanceForDate, streamAttendance, streamMaterials, streamWorkerPayments, streamPayments)
    → DashboardController (binds streams, holds reactive lists)
    → DashboardCalculationService (pure functions over lists)
    → Reactive stats (totalWorkers, presentToday, absentToday, totalHoursToday, todayLabourCost, totalMaterialCost, totalPaymentsMade, pendingPayments)
    → Dashboard UI (Obx → cards, charts, lists)
```

- **Workers** and **attendance (today)** drive: total workers, present today, absent today, total hours today, today labour cost.
- **All attendance** (over a long period) + **workers** → total labour earnings → used for **pending payments** with **worker payments**.
- **Materials** → total material cost and category cost map (for charts).
- **Worker payments** → total payments made; pending = total labour earnings − total payments made. “Recent Worker Payments” on the dashboard uses the same stream.

---

## 3. Stream architecture

### 3.1 Streams used by the dashboard

| Stream | Repository method | Purpose |
|--------|-------------------|--------|
| Workers | `LabourRepository.streamLabour(limit: n)` | Total workers count; labour cost calculation (worker rates). |
| Attendance today | `AttendanceRepository.streamAttendanceForDate(today)` | Present/absent today, total hours today, today labour cost. |
| Attendance (period) | `AttendanceRepository.streamAttendance(fromDate, toDate, limit)` | Total labour earnings (all time / long period) for pending calculation. |
| Materials | `MaterialRepository.streamMaterials(limit: n)` | Total material cost, category breakdown. |
| Worker payments | `WorkerPaymentRepository.streamWorkerPayments(limit: n)` | Total payments made to workers; pending = earnings − this; also “Recent Worker Payments” list. |

### 3.2 Binding in DashboardController

- Controller subscribes to each stream in `_bindStreams()` (called from `onReady()` and from `refreshStreams()` on retry).
- On each emission:
  - The corresponding reactive list is updated (e.g. `workers.assignAll(list)`).
  - `_updateStats()` is called once, which recomputes all stats via `DashboardCalculationService` and assigns to Rx variables.
- Stream errors are caught per stream; `loadError` is set so the UI can show an error state and a retry action without crashing.

---

## 4. Calculation logic

### 4.1 DashboardCalculationService (pure functions)

All functions take in-memory lists (or scalars) and return a single value. No Firestore or streams.

- **calculateTotalWorkers(workers)** → `workers.length`.
- **calculatePresentToday(attendanceToday)** → count where `isPresent`.
- **calculateAbsentToday(attendanceToday)** → count where `isAbsent`.
- **calculateTotalHoursToday(attendanceToday)** → sum of `totalHours`.
- **calculateTodayLabourCost(attendanceToday, workers)** → for each today-attendance, find worker by `workerId`, then `PaymentCalculator.paymentForAttendance(attendance, worker)`; sum.
- **calculateTotalLabourEarnings(attendance, workers)** → same as above over full attendance list (used for “all time” labour earnings).
- **calculateTotalMaterialCost(materials)** → sum of `material.totalPrice` (quantity × pricePerUnit is already in `totalPrice`).
- **calculateTotalPaymentsMade(workerPayments)** → sum of `amountPaid`.
- **calculatePendingPayments(totalLabourEarnings, totalPaymentsMade)** → `(totalLabourEarnings - totalPaymentsMade).clamp(0, infinity)`.
- **calculateMaterialCostByCategory(materials)** → map from category display name to sum of `totalPrice` (for category chart).
- **calculateLabourCostByDay(attendance, workers, startDate, endDate)** → map from date to labour cost for that day (for Labour Cost Chart). Used when filter is Today / This Week / This Month.
- **calculateAttendanceByDay(attendance, startDate, endDate)** → map from date to `(present, absent)` counts (for Attendance Chart).

### 4.2 Filter and period charts

- **Filter (Today / This Week / This Month)** drives the date range `(start, end)` used for period charts.
- When the user changes the filter, `setFilter()` updates `filter` and calls `_updateStats()`, which recomputes `labourCostByDay` and `attendanceByDay` for that range. So changing the filter recomputes dashboard period stats and the Labour Cost and Attendance charts update.
- **Labour Cost Chart** shows a bar per day (labour cost) for the selected period.
- **Attendance Chart** shows grouped bars per day (present vs absent) for the selected period.
- **Material Cost Chart** is the category breakdown (bar per category); not filter-dependent.

### 4.3 Labour cost rules (PaymentCalculator)

- **Hourly:** `payment = hoursWorked × hourlyRate + overtimeHours × hourlyRate`; plus fixed `overtimeAmount` when `overtimeEnabled`.
- **Daily (fixed):**
  - Full day / present / overtime → `dailyRate`.
  - Half day → `dailyRate / 2`.
  - Absent / leave → `0`.
  - Overtime hours × (hourlyRate or dailyRate/8) and optional `overtimeAmount` added when applicable.

### 4.4 Material cost

- **Total material cost** = sum of `material.totalPrice` (each row is `quantity × pricePerUnit`).

### 4.5 Payments and pending

- **Total payments made** = sum of all **worker payment** records’ `amountPaid` (from `worker_payments` collection).
- **Pending payments** = total labour earnings (from attendance + workers via PaymentCalculator) − total payments made; never negative.

---

## 5. Performance strategy

- **Indexed / limited queries:**  
  - `streamAttendanceForDate(date)` uses a single-day query.  
  - `streamAttendance(fromDate, toDate, limit)` and other streams use `limit` to avoid loading unbounded data.
- **Recompute on emission:**  
  Stats are recomputed only when a stream emits; no polling. All calculations are in-memory over the already-loaded lists.
- **Single stats update:**  
  Each stream callback updates one list and then calls `_updateStats()` once, so we avoid redundant work when multiple streams emit close together (we could debounce later if needed).
- **Bounded “all attendance”:**  
  For total labour earnings we use `streamAttendance(fromDate: twoYearsAgo, toDate: now, limit: 2000)` so the dashboard does not load the entire history.

---

## 6. Error handling and loading

- **Stream errors:** Each subscription has `onError`; it sets `loadError.value` and still calls `_updateStats()` so partial data can be shown.
- **Calculation errors:** `_updateStats()` is wrapped in try/catch; on exception, `loadError` is set and the app does not crash.
- **Loading:** `isLoading` is set to `true` when binding streams and set to `false` after the first successful `_updateStats()`. The UI shows a loading indicator until then.
- **Retry:** The view exposes a “Retry” button that calls `controller.refreshStreams()` to re-bind all streams.

---

## 7. UI binding (GetX)

- All 8 stat cards and the charts read from controller Rx vars inside `Obx()` so any change in stats triggers a rebuild.
- Filter (Today / This Week / This Month) is stored in `controller.filter` and can be used by charts for period-specific data in the future; the main 8 cards always show “today” and “all time” as described above.
- Recent lists (materials, labour, payments) are bound to `controller.materials`, `controller.workers`, and `controller.recentPayments` inside `Obx()`.

---

## 8. File roles

| File | Role |
|------|------|
| `lib/core/services/dashboard_calculation_service.dart` | Pure calculation functions for dashboard stats. |
| `lib/core/services/payment_calculator.dart` | Labour payment from attendance (hourly/daily + overtime). |
| `lib/modules/dashboard_module/controllers/dashboard_controller.dart` | Binds Firestore streams, holds reactive lists and stats, calls calculation service. |
| `lib/modules/dashboard_module/views/dashboard_view.dart` | Realtime dashboard UI: 8 cards, charts, filter chips, recent lists, loading/error. |
| `lib/modules/dashboard_module/widgets/summary_card.dart` | Reusable stat card (currency or count/hours via prefix/suffix). |
| `lib/modules/dashboard_module/widgets/labour_cost_chart.dart` | Bar chart: labour cost per day for the selected filter period. |
| `lib/modules/dashboard_module/widgets/attendance_chart.dart` | Grouped bar chart: present vs absent per day for the selected filter period. |
| Repositories (Labour, Attendance, Material, Payment, WorkerPayment) | Expose stream APIs; dashboard only consumes them. |

This architecture keeps the dashboard read-only, fully reactive, and aligned with the existing Worker, Attendance, Payment, and Material modules.
