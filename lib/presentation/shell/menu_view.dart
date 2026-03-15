import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_routes.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  static const _menuItems = [
    _MenuItem(route: AppRoutes.materials, label: AppStrings.materials, icon: Icons.inventory_2),
    _MenuItem(route: AppRoutes.labour, label: AppStrings.labour, icon: Icons.engineering),
    _MenuItem(route: AppRoutes.attendance, label: AppStrings.attendance, icon: Icons.event_available),
    _MenuItem(route: AppRoutes.workerPayments, label: AppStrings.workerPayments, icon: Icons.payments),
    _MenuItem(route: AppRoutes.reports, label: AppStrings.reports, icon: Icons.analytics),
    _MenuItem(route: AppRoutes.settings, label: AppStrings.settings, icon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (route) => Get.toNamed(route),
            itemBuilder: (BuildContext context) {
              return _menuItems
                  .map<PopupMenuEntry<String>>(
                    (e) => PopupMenuItem<String>(
                      value: e.route,
                      child: Row(
                        children: [
                          Icon(e.icon, size: 20),
                          const SizedBox(width: 16),
                          Text(e.label),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _menuItems.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Icon(item.icon)),
              title: Text(item.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(item.route),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.route, required this.label, required this.icon});
  final String route;
  final String label;
  final IconData icon;
}
