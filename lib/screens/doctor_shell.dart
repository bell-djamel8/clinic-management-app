import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/sidebar.dart';
import 'appointments_screen.dart';
import 'billing_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'new_visit_screen.dart';
import 'statistics_screen.dart';
import 'waiting_room_screen.dart';

/// Conteneur principal de l'interface médecin : barre latérale + écrans
class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _selectedIndex = 0;

  final List<SidebarItem> _items = [
    SidebarItem(Icons.dashboard_outlined, 'Archive des patients'),
    SidebarItem(Icons.event_seat_outlined, 'Salle d\'attente'),
    SidebarItem(Icons.add_circle_outline, 'Nouvelle visite'),
    SidebarItem(Icons.event_outlined, 'Rendez-vous'),
    SidebarItem(Icons.receipt_long_outlined, 'Facturation'),
    SidebarItem(Icons.bar_chart_outlined, 'Statistiques'),
  ];

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const WaitingRoomScreen(currentRole: 'doctor'),
      const NewVisitScreen(),
      const AppointmentsScreen(),
      const BillingScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            items: _items,
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
            onLogout: _logout,
            roleLabel: 'Interface Médecin',
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
