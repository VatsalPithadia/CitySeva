import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../user/user_home.dart';
import '../authority/authority_home.dart';
import '../government/government_home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkIfSeen();
  }

  Future<void> _checkIfSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (done && mounted) {
      final provider = context.read<ComplaintProvider>();
      final user = provider.currentUser;
      Widget screen;
      if (user == null) {
        screen = const LoginScreen();
      } else if (user.role == 'authority') {
        screen = const AuthorityHome();
      } else if (user.role == 'government') {
        screen = const GovernmentHome();
      } else {
        screen = const UserHome();
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
      return;
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    final provider = context.read<ComplaintProvider>();
    final user = provider.currentUser;
    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (user.role == 'authority') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthorityHome()));
    } else if (user.role == 'government') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GovernmentHome()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserHome()));
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final _pages = const [
    _ManualPage(
      pageNumber: 0,
      icon: Icons.menu_book_outlined,
      title: 'User Manual',
      subtitle: 'How to Generate a Complaint',
      gradient: [Color(0xFF0D47A1), Color(0xFF1565C0)],
      steps: [],
      isWelcome: true,
      welcomeDescription:
          'This guide will walk you through how to register, submit and track a civic complaint on CitySeva. Follow the steps on the next pages to get started.',
    ),
    _ManualPage(
      pageNumber: 1,
      icon: Icons.app_registration_outlined,
      title: 'Step 1',
      subtitle: 'Register & Login',
      gradient: [Color(0xFF1565C0), Color(0xFF1976D2)],
      isWelcome: false,
      steps: [
        _Step(Icons.person_add_outlined, 'Open the app and tap Register'),
        _Step(Icons.badge_outlined, 'Enter your Full Name, Phone & Email'),
        _Step(Icons.lock_outline, 'Set a password (min 6 characters)'),
        _Step(Icons.how_to_reg_outlined, 'Select role as Citizen'),
        _Step(Icons.login_outlined, 'Tap Create Account to register'),
        _Step(Icons.check_circle_outline, 'Login with your email & password'),
      ],
    ),
    _ManualPage(
      pageNumber: 2,
      icon: Icons.edit_note_outlined,
      title: 'Step 2',
      subtitle: 'Fill Complaint Details',
      gradient: [Color(0xFF1976D2), Color(0xFF0288D1)],
      isWelcome: false,
      steps: [
        _Step(Icons.home_outlined, 'Go to Home tab after login'),
        _Step(Icons.title_outlined, 'Enter a clear Title for the issue'),
        _Step(Icons.description_outlined, 'Write a detailed Description'),
        _Step(Icons.business_outlined, 'Select the correct Department'),
        _Step(Icons.info_outline, 'Example: Pothole → Road & Infrastructure'),
        _Step(Icons.info_outline, 'Example: No water → Water Supply'),
      ],
    ),
    _ManualPage(
      pageNumber: 3,
      icon: Icons.location_on_outlined,
      title: 'Step 3',
      subtitle: 'Add Location',
      gradient: [Color(0xFF0288D1), Color(0xFF0097A7)],
      isWelcome: false,
      steps: [
        _Step(Icons.my_location_outlined, 'Tap "Use Current Location (GPS)"'),
        _Step(Icons.gps_fixed, 'Allow location permission when asked'),
        _Step(Icons.edit_location_alt_outlined, 'OR type the address manually'),
        _Step(Icons.add_location_alt_outlined, 'Use quick chips: Near Home, Market Area etc.'),
        _Step(Icons.check_circle_outline, 'GPS coordinates will be saved automatically'),
      ],
    ),
    _ManualPage(
      pageNumber: 4,
      icon: Icons.photo_camera_outlined,
      title: 'Step 4',
      subtitle: 'Add Photos (Optional)',
      gradient: [Color(0xFF0097A7), Color(0xFF00796B)],
      isWelcome: false,
      steps: [
        _Step(Icons.camera_alt_outlined, 'Tap Camera to take a live photo'),
        _Step(Icons.photo_library_outlined, 'OR tap Gallery to pick from phone'),
        _Step(Icons.filter_5_outlined, 'You can add up to 5 photos'),
        _Step(Icons.close, 'Tap X on a photo to remove it'),
        _Step(Icons.lightbulb_outline, 'Tip: Clear photos speed up resolution'),
      ],
    ),
    _ManualPage(
      pageNumber: 5,
      icon: Icons.send_outlined,
      title: 'Step 5',
      subtitle: 'Submit the Complaint',
      gradient: [Color(0xFF00796B), Color(0xFF2E7D32)],
      isWelcome: false,
      steps: [
        _Step(Icons.checklist_outlined, 'Review all details before submitting'),
        _Step(Icons.send_outlined, 'Tap Submit Complaint button'),
        _Step(Icons.confirmation_number_outlined, 'You will get a unique Complaint ID'),
        _Step(Icons.visibility_outlined, 'Complaint is instantly visible to authorities'),
        _Step(Icons.track_changes_outlined, 'Tap Track Status to follow progress'),
      ],
    ),
    _ManualPage(
      pageNumber: 6,
      icon: Icons.notifications_active_outlined,
      title: 'Step 6',
      subtitle: 'Track & Get Updates',
      gradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      isWelcome: false,
      steps: [
        _Step(Icons.list_alt_outlined, 'Go to My Complaints tab anytime'),
        _Step(Icons.verified_outlined, 'Status: Submitted → Verified → Assigned'),
        _Step(Icons.construction_outlined, 'Status: Work Started → Completed'),
        _Step(Icons.notifications_outlined, 'Get notified at every status change'),
        _Step(Icons.star_outline_rounded, 'Rate the work after it is completed'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _pages[i],
          ),
          // Skip button
          Positioned(
            top: 52,
            right: 20,
            child: TextButton(
              onPressed: _finish,
              child: const Text('Skip', style: TextStyle(color: Colors.white70, fontSize: 15)),
            ),
          ),
          // Page indicator + button
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Back', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String text;
  const _Step(this.icon, this.text);
}

class _ManualPage extends StatelessWidget {
  final int pageNumber;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<_Step> steps;
  final bool isWelcome;
  final String welcomeDescription;

  const _ManualPage({
    required this.pageNumber,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.steps,
    required this.isWelcome,
    this.welcomeDescription = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5)),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
              const SizedBox(height: 20),

              // Welcome page
              if (isWelcome) ...[
                // App logo
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    welcomeDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        height: 1.7),
                  ),
                ),
                const SizedBox(height: 20),
                // Quick overview chips
                const Text('This manual covers:',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Register & Login',
                    'Fill Details',
                    'Add Location',
                    'Add Photos',
                    'Submit',
                    'Track Status',
                  ].map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(s,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      )).toList(),
                ),
              ],

              // Steps pages
              if (!isWelcome)
                ...steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final step = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i % 2 == 0 ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step.icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            step.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
