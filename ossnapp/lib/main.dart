import 'package:flutter/material.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'models/feed_mode.dart';

void main() {
  runApp(const FlutterSocialApp());
}

class FlutterSocialApp extends StatelessWidget {
  const FlutterSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSSN Android',
      theme: ThemeData(
        primaryColor: const Color(0xFF00AEEF),
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00AEEF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00AEEF),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/feed': (_) => const SocialHome(),
      },
    );
  }
}

class SocialHome extends StatefulWidget {
  const SocialHome({super.key});

  @override
  State<SocialHome> createState() => _SocialHomeState();
}

class _SocialHomeState extends State<SocialHome>
    with SingleTickerProviderStateMixin {
  bool _sidebarOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _sidebarAnimation;

  Map<String, dynamic>? _authPayload;
  FeedMode _currentFeedMode = FeedMode.user;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(begin: -220, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _authPayload = args;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
      if (_sidebarOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _switchFeed(FeedMode mode) {
    setState(() {
      _currentFeedMode = mode;
      _sidebarOpen = false;
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSidebar() {
    final userName = _authPayload?['fullname']?.toString() ?? 'Guest User';
    final iconData = _authPayload?['icon'];
    final userAvatarUrl = (iconData is Map) ? iconData['small'] as String? : null;

    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          bottom: 0,
          left: _sidebarAnimation.value,
          child: Container(
            width: 220,
            color: const Color(0xFF222931),
            child: Column(
              children: [
                const SizedBox(height: 32),
                ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: userAvatarUrl != null && userAvatarUrl.isNotEmpty
                        ? NetworkImage(userAvatarUrl)
                        : null,
                    child: (userAvatarUrl == null || userAvatarUrl.isEmpty)
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Edit Profile',
                      style: TextStyle(color: Colors.white70)),
                ),
                const Divider(color: Colors.white24),
                _SidebarNavItem(
                  icon: Icons.rss_feed,
                  label: 'News Feed',
                  onTap: () => _switchFeed(FeedMode.community),
                ),
                _SidebarNavItem(icon: Icons.people, label: 'Friends'),
                _SidebarNavItem(icon: Icons.photo, label: 'Photos'),
                _SidebarNavItem(icon: Icons.notifications, label: 'Notifications'),
                _SidebarNavItem(icon: Icons.message, label: 'Messages'),
                _SidebarNavItem(icon: Icons.group, label: 'Groups'),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF313A43),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarBackdrop() {
    return _sidebarOpen
        ? Positioned.fill(
            child: GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF00AEEF),
                        height: 56,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: _toggleSidebar,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'OSSN Android',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            const Spacer(),
                            IconButton(
                                icon: const Icon(Icons.notifications,
                                    color: Colors.white),
                                onPressed: () {}),
                            IconButton(
                                icon: const Icon(Icons.mail, color: Colors.white),
                                onPressed: () {}),
                            IconButton(
                                icon: const Icon(Icons.account_circle,
                                    color: Colors.white),
                                onPressed: () {}),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _authPayload != null
                            ? FeedScreen(
                                authPayload: _authPayload!,
                                mode: _currentFeedMode,
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSidebar(),
            _buildSidebarBackdrop(),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SidebarNavItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}