# Reports Module Architecture

This document describes the data sources, calculation logic, realtime streams, and performance strategy for the Reports module in the Construction Management Application.

---

## Overview

The Reports module provides an analytics dashboard for construction data: worker activity, attendance, labour costs, worker payments, and material usage. All metrics are derived from existing Firestore collections and update in realtime via streams.

---

## Data Sources

Reports read from these Firestore collections (through repository interfaces):

| Collection / Source | Purpose |
|--------------------|--------|
| **workers** (labour) | Total workers, labour cost (earnings), worker names for search and payment distribution |
| **attendance** | Present/absent today, period attendance, daily labour cost and attendance charts |
| **worker_payments** | Total payments made, pending labour payments, payment history by day |
| **materials** | Total material cost, category breakdown, top materials, material usage trends |

- **workers**: `LabourRepositoryInterface.streamLabour(limit: N)` — stream of all workers (capped).
- **attendance**:  
  - `streamAttendanceForDate(today)` — today’s attendance for “Present Today” / “Absent Today”.  
  - `streamAttendance(fromDate, toDate, limit)` — attendance in the selected filter range for period stats and charts.
- **worker_payments**: `WorkerPaymentRepositoryInterface.streamWorkerPayments(limit: N)` — all payment records.
- **materials**: `MaterialRepositoryInterface.streamMaterials(limit: N)` — all materials (capped).

All four are consumed as **Firestore-backed streams** so the Reports UI updates in realtime when data changes.

---

## Calculation Logic

Calculations are centralized in **`DashboardCalculationService`** (shared with the Dashboard module). The Reports controller does not duplicate formulas; it passes streamed data into these helpers.

### Overview summary cards

- **Total Workers**: `calculateTotalWorkers(workers)` → `workers.length`.
- **Total Present Today**: `calculatePresentToday(attendanceToday)` → count where `isPresent`.
- **Total Absent Today**: `calculateAbsentToday(attendanceToday)` → count where `isAbsent`.
- **Total Labour Cost**: Sum of labour *earnings* in the selected period (not “today only”).  
  `totalLabourEarnings` = `calculateTotalLabourEarnings(attendance: attendancePeriod, workers: workers)` (uses `PaymentCalculator.paymentForAttendance` per record).
- **Total Material Cost**: `calculateTotalMaterialCost(materials)` → sum of `material.totalPrice`.
- **Total Payments Made**: `calculateTotalPaymentsMade(workerPayments)` → sum of `amountPaid`.
- **Pending Labour Payments**: `calculatePendingPayments(totalLabourEarnings, totalPaymentsMade)` → `(earnings - paid).clamp(0, ∞)`.

### Attendance report

- **Present / Absent count**: From `attendancePeriod`: `where(isPresent).length` and `where(isAbsent).length`.
- **Attendance percentage**: `periodPresent / (periodPresent + periodAbsent) * 100` (0 if no records).
- **Daily attendance chart**: `calculateAttendanceByDay(attendancePeriod, startDate, endDate)` → map of date → `(present, absent)`.

### Labour cost report

- **Labour cost by day**: `calculateLabourCostByDay(attendancePeriod, workers, startDate, endDate)` → map of date → labour cost (via `PaymentCalculator.paymentForAttendance` per attendance record).
- Daily/Weekly/Monthly views are implied by the same map and the selected **filter range** (Today / This Week / This Month / Custom).

### Payment report

- **Total paid**: Same as “Total Payments Made” (sum of `amountPaid`).
- **Pending**: Same as “Pending Labour Payments”.
- **Payment history chart**: Payments aggregated by day: for each `WorkerPaymentRecordModel`, date is normalized to start-of-day and amounts are summed into `paymentByDay`.

### Material usage report

- **Total material cost**: Same as “Total Material Cost”.
- **Category breakdown**: `calculateMaterialCostByCategory(materials)` → map category display name → sum of `totalPrice`.
- **Top materials**: From `filteredMaterials`, sorted by `totalPrice` descending, take top 5.
- **Material cost by type / over time**: Category chart uses the same category map; “over time” can be derived from material dates if the UI adds a time-series (current implementation focuses on category breakdown and top list).

---

## Realtime Streams

- **ReportsController** subscribes to:
  - `streamLabour`
  - `streamAttendanceForDate(today)`
  - `streamAttendance(fromDate, toDate)` — **re-subscribed when the filter changes** so the period matches “Today”, “This Week”, “This Month”, or “Custom Range”.
  - `streamMaterials`
  - `streamWorkerPayments`

- On each emission, the controller updates observable lists (`workers`, `attendanceToday`, `attendancePeriod`, `materials`, `workerPayments`) and then calls **`_updateStats()`**, which:
  - Recomputes all summary card values and chart data (labourCostByDay, attendanceByDay, paymentByDay, categoryCostMap).
  - Uses **reactive getters** (e.g. `totalLabourEarnings`, `periodPresent`, `attendancePercentageValue`) so the UI (Obx) rebuilds when any dependency changes.

- **Filter change**: `setFilter(...)` or `setCustomDateRange(...)` updates the filter, calls `_updatePeriodStream()` to re-subscribe `streamAttendance(fromDate, toDate)` for the new range, and then `_updateStats()` so all reports reflect the new period immediately.

---

## Performance Strategy

- **Limit stream sizes**: Labour, materials, and worker_payments use fixed limits (e.g. 500 materials, 1000 payments, labour page size × 3). Attendance period uses a high limit (2000) to cover the selected range without loading the entire collection.
- **Filtered period attendance**: Only attendance in the selected date range is requested via `fromDate`/`toDate` in `streamAttendance`, so the backend (Firestore) can use indexes and return only relevant documents.
- **No full collection load**: Reports never load “all documents” without a limit; all streams are capped or filtered by date.
- **Single calculation pass**: `_updateStats()` runs once per stream batch and recomputes all derived state (cards + chart maps) in one go, avoiding repeated iterations over the same data.
- **Search is in-memory**: Search (worker name, material name, amount) is applied in the controller with getters (`filteredWorkers`, `filteredMaterials`, `filteredWorkerPayments`) over already-loaded lists. No extra Firestore queries for search.

---

## Error Handling

- Each stream’s `onError` sets `loadError` and triggers `_updateStats()` so the UI can show an error message and retry (e.g. “Failed to load workers”) without crashing.
- Calculation errors inside `_updateStats()` are caught; the error is logged and `loadError` is set so the screen shows a retry state instead of throwing.
- Null/empty data: All calculation helpers accept empty lists and return 0 or empty maps; the UI uses `EmptyStateWidget` and safe defaults (e.g. 0% attendance when there are no records).

---

## Routing and Navigation

- Route: **`/reports`** (defined in `AppRoutes.reports` and `AppPages`).
- **ReportsBinding** lazily puts `ReportsController`.
- The shell menu includes a “Reports” item that navigates to `/reports`. Opening and closing the Reports screen does not require any special handling; GetX closes the route when navigating away, and the controller is disposed when the route is removed, cleaning up all stream subscriptions in `onClose()`.

---

## File Layout

- **Binding**: `lib/modules/reports_module/bindings/reports_binding.dart`
- **Controller**: `lib/modules/reports_module/controllers/reports_controller.dart`
- **View**: `lib/modules/reports_module/views/reports_view.dart`
- **Calculations**: `lib/core/services/dashboard_calculation_service.dart` (shared with Dashboard)
- **Charts**: Reused from dashboard module: `LabourCostChart`, `AttendanceChart`, `CategoryBreakdownChart`

---

## Testing

- **Unit tests** (`test/modules/reports_module/reports_controller_test.dart`): Filter date range, report calculations (totals, attendance, payments, materials) with fake repositories, and search filtering (worker name, material name, amount).
- **Widget tests** (`test/modules/reports_module/reports_view_test.dart`): Reports screen shows app bar, filter chips (Today, This Week, This Month, Custom Range), Overview, Attendance Report, Labour Cost Report, Payment Report, Material Usage Report, search field, and summary cards (e.g. Total Workers, Total Material Cost).
- **Calculation logic** is covered by `test/core/services/dashboard_calculation_service_test.dart` (attendance stats, payment totals, material totals, labour cost by day, etc.).
