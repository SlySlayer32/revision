import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/widgets/adaptive_scaffold.dart';
import 'package:revision/features/authentication/cubit/authentication_cubit.dart';
import 'package:revision/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:revision/features/dashboard/view/dashboard_body.dart';
import 'package:revision/features/dashboard/view/dashboard_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const DashboardPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.select(
      (DashboardCubit cubit) => cubit.state.selectedIndex,
    );
    final user = context.select((AuthenticationCubit cubit) => cubit.state.user);

    return AdaptiveScaffold(
      scaffoldKey: scaffoldKey,
      appBar: AppBar(
        title: Text(user.email ?? 'Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthenticationCubit>().requestLogout();
            },
          ),
        ],
      ),
      drawer: const DashboardDrawer(),
      body: const DashboardBody(),
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        context.read<DashboardCubit>().setSelectedIndex(index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: 'Gallery',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_fix_high_outlined),
          selectedIcon: Icon(Icons.auto_fix_high),
          label: 'AI Tools',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
