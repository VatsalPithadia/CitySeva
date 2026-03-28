import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/complaint_provider.dart';
import '../../services/auth_service.dart';
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

    if (!done) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    if (!mounted) return;

    // Try token verification
    final authResult = await AuthService.verifyToken();
    if (authResult.success && authResult.user != null) {
      if (mounted) {
        await context.read<ComplaintProvider>().saveUser(authResult.user!);
        _navigateTo(authResult.user!.role);
      }
      return;
    }

    // Fallback to local user
    final provider = context.read<ComplaintProvider>();
    await Future.delayed(const Duration(milliseconds: 500));
    final user = provider.currentUser;
    if (user != null && mounted) {
      _navigateTo(user.role);
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _navigateTo(String role) {
    Widget screen;
    if (role == 'authority') {
      screen = const AuthorityHome();
    } else if (role == 'government') {
      screen = const GovernmentHome();
    } else {
      screen = const UserHome();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  static const _pages = [
    _Page(
      gradient: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      isWelcome: true,
    ),
    _Page(
      gradient: [Color(0xFF1565C0), Color(0xFF0288D1)],
      stepNumber: 1,
      stepTitle: 'Register & Login',
      stepIcon: Icons.person_add_outlined,
      stepDescription: 'Create your account with your name, email and phone number. Select your role as Citizen and set a secure password to get started.',
      points: [
        'Open app and tap Register tab',
        'Fill in Name, Phone and Email',
        'Set a password (min 6 characters)',
        'Select role as Citizen',
        'Tap Create Account',
      ],
    ),
    _Page(
      gradient: [Color(0xFF0288D1), Color(0xFF00838F)],
      stepNumber: 2,
      stepTitle: 'Fill Complaint Details',
      stepIcon: Icons.edit_note_outlined,
      stepDescription: 'Go to the Home tab and describe your civic issue clearly. A good title and detailed description helps authorities resolve it faster.',
      points: [
        'Go to Home tab after login',
        'Enter a clear and specific Title',
        'Write a detailed Description',
        'Select the correct Department',
        'Example: Pothole → Road & Infrastructure',
      ],
    ),
    _Page(
      gradient: [Color(0xFF00838F), Color(0xFF00695C)],
      stepNumber: 3,
      stepTitle: 'Add Location',
      stepIcon: Icons.location_on_outlined,
      stepDescription: 'Pin the exact location of the issue using GPS or type the address manually. Accurate location ensures faster field response.',
      points: [
        'Tap "Use Current Location (GPS)"',
        'Allow location permission',
        'OR type address manually',
        'Use quick chips for common areas',
        'GPS coordinates saved automatically',
      ],
    ),
    _Page(
      gradient: [Color(0xFF00695C), Color(0xFF2E7D32)],
      stepNumber: 4,
      stepTitle: 'Add Photos & Submit',
      stepIcon: Icons.photo_camera_outlined,
      stepDescription: 'Attach photos of the issue for faster resolution. Once ready, tap Submit to file your complaint and receive a unique Complaint ID.',
      points: [
        'Tap Camera or Gallery to add photos',
        'Add up to 5 photos as evidence',
        'Review all details carefully',
        'Tap Submit Complaint button',
        'Save your unique Complaint ID',
      ],
    ),
    _Page(
      gradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      stepNumber: 5,
      stepTitle: 'Track & Give Feedback',
      stepIcon: Icons.track_changes_outlined,
      stepDescription: 'Monitor your complaint status in real time from My Complaints tab. Once resolved, rate the government\'s performance.',
      points: [
        'Go to My Complaints tab',
        'Track: Submitted → Verified → Assigned',
        'Track: Work Started → Completed',
        'Get notified at every status change',
        'Rate the work once completed',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
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
            child: SafeArea(
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                ),
              ),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
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
                      if (_currentPage > 0) ...[
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
                        const SizedBox(width: 12),
                      ],
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
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final List<Color> gradient;
  final bool isWelcome;
  final int stepNumber;
  final String stepTitle;
  final IconData stepIcon;
  final String stepDescription;
  final List<String> points;

  const _Page({
    required this.gradient,
    this.isWelcome = false,
    this.stepNumber = 0,
    this.stepTitle = '',
    this.stepIcon = Icons.circle,
    this.stepDescription = '',
    this.points = const [],
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
        child: isWelcome ? _buildWelcome() : _buildStep(),
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 160),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/images/app_logo.png',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'CitySeva',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          Text(
            'From Complaints to Care - Instantly',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book_outlined, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'How to Report a Complaint',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This quick guide will show you how to register, submit and track a civic complaint in just a few simple steps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Step pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ['Register', 'Fill Details', 'Location', 'Photos', 'Submit', 'Track']
                .asMap()
                .entries
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${e.key + 1}. ${e.value}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step badge + icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step $stepNumber of 5',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Icon + Title
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(stepIcon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  stepTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            stepDescription,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          // Points
          ...points.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          e.value,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
