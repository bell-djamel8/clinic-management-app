import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/sidebar.dart';
import 'appointments_screen.dart';
import 'billing_screen.dart';
import 'login_screen.dart';
import 'waiting_room_screen.dart';

/// Conteneur principal de l'interface réception : salle d'attente,
/// facturation et consultation des rendez-vous (sans accès aux données
/// médicales ni aux statistiques)
class ReceptionistShell extends StatefulWidget {
  const ReceptionistShell({super.key});

  @override
  State<ReceptionistShell> createState() => _ReceptionistShellState();
}

class _ReceptionistShellState extends State<ReceptionistShell> {
  int _selectedIndex = 0;

  final List<SidebarItem> _items = [
    SidebarItem(Icons.event_seat_outlined, 'Salle d\'attente'),
    SidebarItem(Icons.receipt_long_outlined, 'Facturation et paiements'),
    SidebarItem(Icons.event_outlined, 'Rendez-vous'),
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
    final screens = const [
      WaitingRoomScreen(currentRole: 'receptionist'),
      BillingScreen(isReceptionist: true),
      AppointmentsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            items: _items,
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
            onLogout: _logout,
            roleLabel: 'Interface Réception',
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
