import 'package:get/get.dart';
import '../presentation/shell/main_shell_view.dart';
import '../presentation/shell/main_binding.dart';
import '../modules/dashboard_module/views/dashboard_view.dart';
import '../modules/dashboard_module/bindings/dashboard_binding.dart';
import '../modules/materials_module/views/materials_list_view.dart';
import '../modules/materials_module/views/material_form_view.dart';
import '../modules/materials_module/bindings/materials_binding.dart';
import '../modules/labour_module/views/labour_list_view.dart';
import '../modules/labour_module/views/labour_form_view.dart';
import '../modules/labour_module/bindings/labour_binding.dart';
import '../modules/ai_prediction_module/views/ai_prediction_view.dart';
import '../modules/ai_prediction_module/bindings/ai_prediction_binding.dart';
import '../modules/attendance_module/views/attendance_view.dart';
import '../modules/attendance_module/bindings/attendance_binding.dart';
import '../modules/worker_payment_module/views/worker_payment_view.dart';
import '../modules/worker_payment_module/bindings/worker_payment_binding.dart';
import '../modules/reports_module/views/reports_view.dart';
import '../modules/reports_module/bindings/reports_binding.dart';
import '../presentation/settings/settings_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.main,
      page: () => const MainShellView(),
      binding: MainBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.materials,
      page: () => const MaterialsListView(),
      binding: MaterialsBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: AppRoutes.materialForm,
      page: () => const MaterialFormView(),
      binding: MaterialsBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.labour,
      page: () => const LabourListView(),
      binding: LabourBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: AppRoutes.labourForm,
      page: () => const LabourFormView(),
      binding: LabourBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.aiPrediction,
      page: () => const AiPredictionView(),
      binding: AiPredictionBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.attendance,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerPayments,
      page: () => const WorkerPaymentView(),
      binding: WorkerPaymentBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
      transition: Transition.fade,
    ),
  ];
}
