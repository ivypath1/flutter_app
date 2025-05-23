import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ivy_path/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.activeIndex=1});
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.authData?.user;
    
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'IvyPath',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: activeIndex == 1,
                  onTap: () {Navigator.pushNamed(context, '/dashboard');},
                ),
                _DrawerItem(
                  icon: Icons.question_answer,
                  title: 'Practice Questions',
                  isSelected: activeIndex == 2,
                  onTap: () {Navigator.pushNamed(context, '/practice');},
                ),
                _DrawerItem(
                  icon: Icons.book,
                  title: 'Premium Materials',
                  isSelected: activeIndex == 3,
                  onTap: () {Navigator.pushNamed(context, '/materials');},
                ),
                _DrawerItem(
                  icon: Icons.trending_up,
                  title: 'My Progress',
                  isSelected: activeIndex == 4,
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.book,
                  title: 'Discussion forum',
                  isSelected: activeIndex == 5,
                  onTap: () {Navigator.pushNamed(context, '/forum');},
                ),
                _DrawerItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  isSelected: activeIndex == 6,
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  isSelected: activeIndex == 7,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => auth.logout(),
          ),
          const Divider(),
          // User Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      user?.image ?? 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null 
                            ? '${user.firstName} ${user.lastName}'
                            : 'Guest User',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.program ?? 'No Program',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected ? theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class IvyAppBar extends StatelessWidget {
  final String title;
  final bool showMenuButton;
  final List<Widget>? actions;

  const IvyAppBar({
    super.key,
    required this.title,
    this.showMenuButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverAppBar(
      floating: true,
      leading: showMenuButton 
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.headlineMedium,
      ),
      actions: actions ?? [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class IvyNavRail extends StatelessWidget {
  const IvyNavRail({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: false,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.question_answer),
          label: Text('Practice'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.book),
          label: Text('Materials'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.trending_up),
          label: Text('Progress'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications),
          label: Text('Notifications'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
      selectedIndex: 0,
      onDestinationSelected: (index) {
        // Handle navigation
      },
    );
  }
}