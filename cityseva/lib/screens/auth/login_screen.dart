import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../user/user_home.dart';
import '../authority/authority_home.dart';
import '../government/government_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  String _selectedRole = 'citizen';
  bool _obscurePass = true;
  bool _isLoading = false;

  // Demo accounts
  final _demoAccounts = {
    'citizen@demo.com': {'role': 'citizen', 'name': 'Rahul Sharma', 'phone': '9876543210'},
    'authority@demo.com': {'role': 'authority', 'name': 'Officer Priya', 'phone': '9876543211'},
    'govt@demo.com': {'role': 'government', 'name': 'Minister Raj', 'phone': '9876543212'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final email = _emailCtrl.text.trim();
    final demo = _demoAccounts[email];
    final role = demo?['role'] ?? 'citizen';
    final name = demo?['name'] ?? email.split('@')[0];
    final phone = demo?['phone'] ?? '';

    final user = UserModel(
      id: const Uuid().v4(),
      name: name,
      email: email,
      phone: phone,
      role: role,
    );

    if (!mounted) return;
    await context.read<ComplaintProvider>().saveUser(user);
    setState(() => _isLoading = false);
    _navigateByRole(role);
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final user = UserModel(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    await context.read<ComplaintProvider>().saveUser(user);
    setState(() => _isLoading = false);
    _navigateByRole(_selectedRole);
  }

  void _navigateByRole(String role) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              const Text('CitySeva', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text('From Complaints to Care - Instantly', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildLoginForm(), _buildRegisterForm()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDemoChips(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              obscureText: _obscurePass,
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoChips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demo Accounts (tap to fill)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _demoAccounts.entries.map((e) {
              final role = e.value['role']!;
              return ActionChip(
                label: Text(role[0].toUpperCase() + role.substring(1), style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                onPressed: () {
                  _emailCtrl.text = e.key;
                  _passCtrl.text = 'demo123';
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.length < 10 ? 'Enter valid phone' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regEmailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regPassCtrl,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Register As', prefixIcon: Icon(Icons.badge_outlined)),
              items: const [
                DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
                DropdownMenuItem(value: 'authority', child: Text('Authority Officer')),
                DropdownMenuItem(value: 'government', child: Text('Government Official')),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
