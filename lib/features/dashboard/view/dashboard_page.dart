import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/navigation/route_factory.dart' as app_routes;
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/widgets/error_boundary_widget.dart';
import 'package:revision/core/services/preferences_service.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/image_selection/presentation/view/image_selection_page.dart';
import 'package:revision/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:revision/features/dashboard/widgets/session_indicator.dart';
import 'package:revision/features/dashboard/widgets/privacy_aware_user_info.dart';
import 'package:revision/features/dashboard/widgets/responsive_layout.dart';
import 'package:revision/features/dashboard/widgets/role_based_access.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static Route<void> route() {
    return app_routes.RouteFactory.createRoute<void>(
      builder: (_) => const DashboardPage(),
      routeName: RouteNames.dashboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit()..loadDashboard(),
      child: const ErrorBoundaryWidget(
        child: DashboardView(),
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    // Initialize preferences service
    PreferencesService.init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, dashboardState) {
        return BlocBuilder<AuthenticationBloc, AuthenticationState>(
          builder: (context, authState) {
            final user = authState.user;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Revision Dashboard'),
                actions: [
                  // Session indicator
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Center(child: SessionIndicator()),
                  ),
                  // User menu
                  PopupMenuButton<String>(
                    icon: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user?.email != null
                            ? user!.email.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'profile',
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Profile'),
                          subtitle: Text('Profile Settings'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'preferences',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Preferences'),
                          subtitle: Text('App Settings'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: _buildBody(context, dashboardState, user),
            );
          },
        );
      },
    );
  }
  Widget _buildBody(BuildContext context, DashboardState dashboardState, dynamic user) {
    // Show loading state
    if (dashboardState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    // Show error state
    if (dashboardState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dashboardState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<DashboardCubit>().loadDashboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show session expired warning
    if (dashboardState.isSessionExpired) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.orange.shade600),
            const SizedBox(height: 16),
            Text(
              'Session Expired',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your session has expired. Please log in again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AuthenticationBloc>().add(
                  const AuthenticationLogoutRequested(),
                );
              },
              child: const Text('Log In Again'),
            ),
          ],
        ),
      );
    }

    // Main dashboard content with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refreshDashboard(),
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(context, dashboardState, user),
        tablet: _buildTabletLayout(context, dashboardState, user),
        desktop: _buildDesktopLayout(context, dashboardState, user),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, DashboardState dashboardState, dynamic user) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, dashboardState, user),
          const SizedBox(height: 24),
          _buildStatusSection(context),
          const SizedBox(height: 24),
          _buildToolsSection(context, crossAxisCount: 2),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, DashboardState dashboardState, dynamic user) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, dashboardState, user),
          const SizedBox(height: 32),
          _buildStatusSection(context),
          const SizedBox(height: 32),
          _buildToolsSection(context, crossAxisCount: 3),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, DashboardState dashboardState, dynamic user) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, dashboardState, user),
          const SizedBox(height: 40),
          _buildStatusSection(context),
          const SizedBox(height: 40),
          _buildToolsSection(context, crossAxisCount: 4),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, DashboardState dashboardState, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            PrivacyAwareUserInfo(
              email: user?.email ?? 'Unknown User',
              isVisible: dashboardState.preferences?.emailVisibility ?? true,
              onVisibilityChanged: (visible) {
                final preferences = dashboardState.preferences?.copyWith(
                  emailVisibility: visible,
                ) ?? DashboardPreferences(emailVisibility: visible);
                context.read<DashboardCubit>().updatePreferences(preferences);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Status',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ResponsiveLayout(
          mobile: _buildStatusCards(context, isVertical: true),
          tablet: _buildStatusCards(context, isVertical: false),
          desktop: _buildStatusCards(context, isVertical: false),
        ),
      ],
    );
  }

  Widget _buildStatusCards(BuildContext context, {bool isVertical = false}) {
    final cards = [
      _buildStatusCard(
        'Authentication',
        Icons.security,
        Colors.green,
        'Active',
      ),
      _buildStatusCard(
        'AI Services',
        Icons.auto_awesome,
        Colors.blue,
        'Ready',
      ),
    ];

    if (isVertical) {
      return Column(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: card,
        )).toList(),
      );
    } else {
      return Row(
        children: cards.map((card) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: card,
          ),
        )).toList(),
      );
    }
  }

  Widget _buildStatusCard(String title, IconData icon, Color color, String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(status),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context, {int crossAxisCount = 2}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Tools',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ScreenType.getCardAspectRatio(context),
          children: [
            _buildToolCard(
              context,
              'AI Image Generation',
              Icons.auto_awesome,
              Colors.purple,
              '/image-selection',
            ),
            RoleBasedAccess(
              allowedRoles: [UserRoles.user, UserRoles.premium],
              child: _buildToolCard(
                context,
                'Background Editor',
                Icons.landscape,
                Colors.green,
                null,
              ),
            ),
            RoleBasedAccess(
              allowedRoles: [UserRoles.premium],
              child: _buildToolCard(
                context,
                'Smart Enhance',
                Icons.tune,
                Colors.orange,
                null,
              ),
              fallback: _buildToolCard(
                context,
                'Smart Enhance',
                Icons.lock,
                Colors.grey,
                null,
                isLocked: true,
              ),
            ),
            RoleBasedAccess(
              allowedRoles: [UserRoles.premium, UserRoles.admin],
              child: _buildToolCard(
                context,
                'Batch Processing',
                Icons.inventory,
                Colors.blue,
                null,
              ),
              fallback: _buildToolCard(
                context,
                'Batch Processing',
                Icons.lock,
                Colors.grey,
                null,
                isLocked: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String? route, {
    bool isLocked = false,
  }) {
    return Card(
      child: InkWell(
        onTap: isLocked ? null : () => route != null
            ? _navigateToFeature(context, route)
            : _showComingSoonDialog(context),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isLocked ? Colors.grey : color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : null,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(height: 4),
                Text(
                  'Premium Feature',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    // Log user action
    context.read<DashboardCubit>().logUserAction('menu_action', data: {
      'action': action,
    });

    switch (action) {
      case 'logout':
        context.read<AuthenticationBloc>().add(
          const AuthenticationLogoutRequested(),
        );
        break;
      case 'profile':
        _showComingSoonDialog(context);
        break;
      case 'preferences':
        _showPreferencesDialog(context);
        break;
    }
  }

  void _navigateToFeature(BuildContext context, String route) {
    // Log user action
    context.read<DashboardCubit>().logUserAction('feature_navigation', data: {
      'route': route,
    });

    switch (route) {
      case '/image-selection':
        Navigator.of(context).push(
          app_routes.RouteFactory.createRoute<void>(
            builder: (context) => const ImageSelectionPage(),
            routeName: RouteNames.imageSelection,
          ),
        );
        break;
      default:
        _showComingSoonDialog(context);
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'This feature is currently under development and will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final preferences = state.preferences ?? const DashboardPreferences();
          
          return AlertDialog(
            title: const Text('Preferences'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    subtitle: Text(preferences.theme),
                    trailing: DropdownButton<String>(
                      value: preferences.theme,
                      items: const [
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        DropdownMenuItem(value: 'system', child: Text('System')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          context.read<DashboardCubit>().updatePreferences(
                            preferences.copyWith(theme: value),
                          );
                        }
                      },
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.save),
                    title: const Text('Auto Save'),
                    subtitle: const Text('Automatically save your work'),
                    value: preferences.autoSave,
                    onChanged: (value) {
                      context.read<DashboardCubit>().updatePreferences(
                        preferences.copyWith(autoSave: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive app notifications'),
                    value: preferences.notifications,
                    onChanged: (value) {
                      context.read<DashboardCubit>().updatePreferences(
                        preferences.copyWith(notifications: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.email),
                    title: const Text('Show Email'),
                    subtitle: const Text('Display email in dashboard'),
                    value: preferences.emailVisibility,
                    onChanged: (value) {
                      context.read<DashboardCubit>().updatePreferences(
                        preferences.copyWith(emailVisibility: value),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
