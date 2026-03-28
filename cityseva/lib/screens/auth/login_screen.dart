import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/auth_service.dart';
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
  final _accessCodeCtrl = TextEditingController();

  String _selectedRole = 'citizen';
  bool _obscurePass = true;
  bool _obscureRegPass = true;
  bool _obscureAccessCode = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMessage = null));
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
    _accessCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await AuthService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      await context.read<ComplaintProvider>().saveUser(result.user!);
      _navigateByRole(result.user!.role);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
      accessCode: _accessCodeCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      await context.read<ComplaintProvider>().saveUser(result.user!);
      _navigateByRole(result.user!.role);
    } else {
      setState(() => _errorMessage = result.message);
    }
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
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
                              ),
                            ],
                          ),
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
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Don\'t have an account? Tap Register above',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
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
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.length < 10 ? 'Enter valid 10 digit phone' : null,
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
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureRegPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
                ),
              ),
              obscureText: _obscureRegPass,
              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Register As', prefixIcon: Icon(Icons.badge_outlined)),
              items: const [
                DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
                DropdownMenuItem(value: 'authority', child: Text('Authority Officer')),
                DropdownMenuItem(value: 'government', child: Text('Government Official')),
              ],
              onChanged: (v) => setState(() {
                _selectedRole = v!;
                _accessCodeCtrl.clear();
              }),
            ),
            if (_selectedRole == 'authority' || _selectedRole == 'government') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedRole == 'authority'
                            ? 'Authority registration requires an official access code provided by your department admin.'
                            : 'Government registration requires an official access code provided by your department admin.',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accessCodeCtrl,
                decoration: InputDecoration(
                  labelText: '${_selectedRole == 'authority' ? 'Authority' : 'Government'} Access Code *',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureAccessCode ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureAccessCode = !_obscureAccessCode),
                  ),
                ),
                obscureText: _obscureAccessCode,
                validator: (v) {
                  if (_selectedRole != 'citizen' && (v == null || v.isEmpty)) {
                    return 'Access code is required';
                  }
                  return null;
                },
              ),
            ],
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
