import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const bootstrapAdminEmail = 'admin@smartgrab.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmartGrabApp());
}

class SmartGrabApp extends StatelessWidget {
  const SmartGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2B7DE9);
    const secondaryBlue = Color(0xFF4FB6FF);
    const surfaceBlue = Color(0xFFF1F6FF);
    const surfaceHigh = Color(0xFFE3EEFF);
    const onSurface = Color(0xFF0E1B2B);

    final colorScheme = const ColorScheme.light().copyWith(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: secondaryBlue,
      onSecondary: Colors.white,
      surface: surfaceBlue,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceHigh,
    );

    const lightWeight = FontWeight.w600;
    final baseTextTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: lightWeight),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: lightWeight),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontWeight: lightWeight),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: lightWeight),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: lightWeight),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: lightWeight),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: lightWeight),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: lightWeight),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: lightWeight),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: lightWeight),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: lightWeight),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontWeight: lightWeight),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: lightWeight),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: lightWeight),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: lightWeight),
    );

    return MaterialApp(
      title: 'SmartGrab',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: surfaceBlue,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: surfaceHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryBlue.withAlpha(64)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryBlue, width: 1.4),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: BorderSide(color: primaryBlue.withAlpha(153)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<UserProfile>(
          future: UserService().ensureProfile(user),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profileSnap.hasError || profileSnap.data == null) {
              return const Scaffold(
                body: Center(child: Text('Failed to load profile.')),
              );
            }

            return MainShell(profile: profileSnap.data!);
          },
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _working = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isSignup) async {
    setState(() {
      _error = null;
      _working = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email and password required.';
        _working = false;
      });
      return;
    }

    try {
      if (isSignup) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Authentication failed.';
      });
    } catch (_) {
      setState(() {
        _error = 'Authentication failed.';
      });
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('SmartGrab')),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Sign in to sync settings and unlock the dashboard. Your data is encrypted in transit and at rest by Firebase.',
              ),
            ),
            const TabBar(tabs: [
              Tab(text: 'Sign In'),
              Tab(text: 'Sign Up'),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  _buildForm(context, isSignup: false),
                  _buildForm(context, isSignup: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isSignup}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _working ? null : () => _submit(isSignup),
            child: Text(_working ? 'Working...' : isSignup ? 'Sign Up' : 'Sign In'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Admin access is managed via Firestore roles.',
          ),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(profile: widget.profile),
      AccountScreen(profile: widget.profile),
      DashboardScreen(profile: widget.profile),
    ];
  }

  void _select(int index) {
    setState(() => _index = index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartGrab')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              accountName: Text(
                widget.profile.isAdmin ? 'Admin' : 'User',
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                widget.profile.email,
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.profile.email.isNotEmpty
                      ? widget.profile.email[0].toUpperCase()
                      : 'S',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: _index == 0,
              onTap: () => _select(0),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account'),
              selected: _index == 1,
              onTap: () => _select(1),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Dashboard'),
              selected: _index == 2,
              onTap: () => _select(2),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bridge = PlatformBridge();
  final _userService = UserService();
  final _minPayController = TextEditingController();
  final _maxDistanceController = TextEditingController();
  final _costPerKmController = TextEditingController();

  bool _accessibilityEnabled = false;
  bool _overlayGranted = false;
  bool _online = false;
  String _lastRecommendation = '';
  DateTime? _lastRecommendationTime;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _minPayController.dispose();
    _maxDistanceController.dispose();
    _costPerKmController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    try {
      final enabled = await _bridge.isAccessibilityEnabled();
      final overlay = await _bridge.isOverlayGranted();
      final lastRec = await _bridge.getLastRecommendation();
      final lastTime = await _bridge.getLastRecommendationTime();
      final settings = await _bridge.getDecisionSettings();
      final online = await _bridge.getOnline();

      _minPayController.text = settings.minPay.toStringAsFixed(2);
      _maxDistanceController.text = settings.maxDistanceKm.toStringAsFixed(1);
      _costPerKmController.text = settings.costPerKm.toStringAsFixed(2);

      setState(() {
        _accessibilityEnabled = enabled;
        _overlayGranted = overlay;
        _lastRecommendation = lastRec;
        _lastRecommendationTime = lastTime;
        _online = online;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final minPay = double.tryParse(_minPayController.text) ?? 7.0;
    final maxDistance = double.tryParse(_maxDistanceController.text) ?? 12.0;
    final costPerKm = double.tryParse(_costPerKmController.text) ?? 0.5;

    setState(() => _saving = true);
    try {
      await _bridge.setDecisionSettings(
        DecisionSettings(
          minPay: minPay,
          maxDistanceKm: maxDistance,
          costPerKm: costPerKm,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleOnline() async {
    final next = !_online;
    await _bridge.setOnline(next);
    await _userService.setOnline(widget.profile.uid, next);
    setState(() => _online = next);
  }

  Future<void> _simulateOffer() async {
    await _bridge.simulateOffer(
      const OfferSimulation(
        app: 'Instacart',
        pay: 10.0,
        distanceKm: 2.0,
      ),
    );
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Go Online',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _online ? 'You are online.' : 'You are offline.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _toggleOnline,
                icon: Icon(_online ? Icons.pause_circle : Icons.play_circle),
                label: Text(_online ? 'Go Offline' : 'Go Online'),
              ),
              const SizedBox(height: 6),
              Text(
                'When online, SmartGrab reads offers from DoorDash and Instacart.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(
                label: 'Accessibility Service',
                value: _accessibilityEnabled ? 'Enabled' : 'Disabled',
                valueColor: _accessibilityEnabled
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: 'Overlay Permission',
                value: _overlayGranted ? 'Granted' : 'Missing',
                valueColor: _overlayGranted
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: 'Parsing',
                value: _online ? 'Online' : 'Offline',
                valueColor: _online
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _bridge.openAccessibilitySettings,
                    icon: const Icon(Icons.accessibility_new),
                    label: const Text('Enable Accessibility'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _bridge.openOverlaySettings,
                    icon: const Icon(Icons.layers_outlined),
                    label: const Text('Grant Overlay'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _refreshStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Last Recommendation',
          child: _loading
              ? const Text('Loading...')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastRecommendation.isEmpty
                          ? 'No recommendation yet.'
                          : _lastRecommendation,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(_lastRecommendationTime),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _simulateOffer,
                      icon: const Icon(Icons.bolt),
                      label: const Text('Simulate Offer'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Decision Settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NumberField(
                label: 'Min Pay (\$)',
                controller: _minPayController,
              ),
              const SizedBox(height: 12),
              _NumberField(
                label: 'Max Distance (km)',
                controller: _maxDistanceController,
              ),
              const SizedBox(height: 12),
              _NumberField(
                label: 'Cost per km (\$)',
                controller: _costPerKmController,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _saveSettings,
                child: Text(_saving ? 'Saving...' : 'Save Settings'),
              ),
              const SizedBox(height: 8),
              Text(
                'Updates apply immediately to the decision engine.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'No timestamp yet.';
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return 'Last update: $date $hour:$minute';
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Account',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${profile.email}'),
              const SizedBox(height: 6),
              Text('User ID: ${profile.uid}'),
              const SizedBox(height: 6),
              Text('Role: ${profile.isAdmin ? 'Admin' : 'User'}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Admin Setup',
          child: const Text(
            'To grant admin access, add a document in Firestore: admins/{uid} with a field email. Set bootstrapAdminEmail in code for auto-admin during development.',
          ),
        ),
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!profile.isAdmin) {
      return const Center(
        child: Text('Admin access required.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Admin Metrics',
          child: FutureBuilder<AdminMetrics>(
            future: AdminService().fetchMetrics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Loading metrics...');
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Text('Failed to load metrics.');
              }

              final metrics = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total users: ${metrics.totalUsers}'),
                  const SizedBox(height: 6),
                  Text('Active users (7d): ${metrics.activeUsers}'),
                  const SizedBox(height: 6),
                  Text('Daily active users: ${metrics.dailyActiveUsers}'),
                  const SizedBox(height: 6),
                  Text('Online today: ${metrics.onlineToday}'),
                  const SizedBox(height: 6),
                  Text('Currently online: ${metrics.onlineNow}'),
                  const SizedBox(height: 8),
                  Text(
                    'Metrics update from Firestore user activity.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class PlatformBridge {
  static const MethodChannel _channel = MethodChannel('smartgrab/platform');

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  Future<bool> isAccessibilityEnabled() async {
    return (await _channel.invokeMethod<bool>('isAccessibilityEnabled')) ??
        false;
  }

  Future<bool> isOverlayGranted() async {
    return (await _channel.invokeMethod<bool>('isOverlayGranted')) ?? false;
  }

  Future<String> getLastRecommendation() async {
    return (await _channel.invokeMethod<String>('getLastRecommendation')) ?? '';
  }

  Future<DateTime?> getLastRecommendationTime() async {
    final millis = await _channel.invokeMethod<int>('getLastRecommendationTime');
    if (millis == null || millis == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<DecisionSettings> getDecisionSettings() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('getDecisionSettings');
    if (map == null) return DecisionSettings.defaults();

    return DecisionSettings(
      minPay: (map['minPay'] as num?)?.toDouble() ?? 7.0,
      maxDistanceKm: (map['maxDistanceKm'] as num?)?.toDouble() ?? 12.0,
      costPerKm: (map['costPerKm'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Future<void> setDecisionSettings(DecisionSettings settings) async {
    await _channel.invokeMethod('setDecisionSettings', settings.toMap());
  }

  Future<bool> getOnline() async {
    return (await _channel.invokeMethod<bool>('getOnline')) ?? false;
  }

  Future<void> setOnline(bool online) async {
    await _channel.invokeMethod('setOnline', online);
  }

  Future<void> simulateOffer(OfferSimulation offer) async {
    await _channel.invokeMethod('simulateOffer', offer.toMap());
  }
}

class DecisionSettings {
  const DecisionSettings({
    required this.minPay,
    required this.maxDistanceKm,
    required this.costPerKm,
  });

  final double minPay;
  final double maxDistanceKm;
  final double costPerKm;

  factory DecisionSettings.defaults() =>
      const DecisionSettings(minPay: 7.0, maxDistanceKm: 12.0, costPerKm: 0.5);

  Map<String, dynamic> toMap() => {
        'minPay': minPay,
        'maxDistanceKm': maxDistanceKm,
        'costPerKm': costPerKm,
      };
}

class OfferSimulation {
  const OfferSimulation({
    required this.app,
    required this.pay,
    required this.distanceKm,
  });

  final String app;
  final double pay;
  final double distanceKm;

  Map<String, dynamic> toMap() => {
        'app': app,
        'pay': pay,
        'distanceKm': distanceKm,
      };
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.isAdmin,
  });

  final String uid;
  final String email;
  final bool isAdmin;
}

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserProfile> ensureProfile(User user) async {
    final email = user.email ?? '';
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'online': false,
      });
    } else {
      await docRef.update({
        'email': email,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    }

    final isAdmin = await _ensureAdmin(user);

    return UserProfile(uid: user.uid, email: email, isAdmin: isAdmin);
  }

  Future<void> setOnline(String uid, bool online) async {
    await _db.collection('users').doc(uid).set({
      'online': online,
      'lastOnlineAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _ensureAdmin(User user) async {
    final adminRef = _db.collection('admins').doc(user.uid);
    final adminDoc = await adminRef.get();
    if (adminDoc.exists) return true;

    final email = user.email ?? '';
    if (bootstrapAdminEmail.isNotEmpty &&
        email.toLowerCase() == bootstrapAdminEmail.toLowerCase()) {
      await adminRef.set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    return false;
  }
}

class AdminMetrics {
  const AdminMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.dailyActiveUsers,
    required this.onlineToday,
    required this.onlineNow,
  });

  final int totalUsers;
  final int activeUsers;
  final int dailyActiveUsers;
  final int onlineToday;
  final int onlineNow;
}

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AdminMetrics> fetchMetrics() async {
    final users = _db.collection('users');
    final totalSnap = await users.get();
    final totalUsers = totalSnap.size;

    final now = DateTime.now();
    final activeSince = Timestamp.fromDate(now.subtract(const Duration(days: 7)));
    final dailySince = Timestamp.fromDate(now.subtract(const Duration(days: 1)));
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySince = Timestamp.fromDate(todayStart);

    final activeSnap =
        await users.where('lastActiveAt', isGreaterThanOrEqualTo: activeSince).get();
    final dailySnap =
        await users.where('lastActiveAt', isGreaterThanOrEqualTo: dailySince).get();
    final onlineTodaySnap =
        await users.where('lastOnlineAt', isGreaterThanOrEqualTo: todaySince).get();
    final onlineNowSnap =
        await users.where('online', isEqualTo: true).get();

    return AdminMetrics(
      totalUsers: totalUsers,
      activeUsers: activeSnap.size,
      dailyActiveUsers: dailySnap.size,
      onlineToday: onlineTodaySnap.size,
      onlineNow: onlineNowSnap.size,
    );
  }
}
