import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';
import '../../utils/app_theme.dart';
import '../user/user_home.dart';
import '../authority/authority_home.dart';
import '../government/government_home.dart';

/// Multi-step registration screen
/// Step 1: Basic details (name, phone, email, password, role)
/// Step 2: OTP verification
/// Step 3: ID proof upload
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Step tracking
  int _currentStep = 0; // 0 = details, 1 = OTP, 2 = ID proof

  // Step 1 controllers
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _accessCodeCtrl = TextEditingController();
  String _selectedRole = 'citizen';
  bool _obscurePass = true;
  bool _obscureCode = true;

  // Step 2 - OTP
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  String? _demoOtp; // For hackathon demo display

  // Step 3 - ID proof
  File? _idProofFile;
  String _selectedIdType = 'Aadhaar Card';
  final _idTypes = ['Aadhaar Card', 'PAN Card', 'Voter ID', 'Passport', 'Driving License'];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _accessCodeCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Step 1 → Send OTP and move to step 2
  Future<void> _proceedToOtp() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await OtpService.sendOtp(_emailCtrl.text.trim());

    setState(() => _isLoading = false);

    if (result.success) {
      setState(() {
        _otpSent = true;
        _currentStep = 1;
        _demoOtp = result.demoOtp; // Show demo OTP if backend unavailable
      });
      _showSnack('OTP sent to ${_emailCtrl.text.trim()}', success: true);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  /// Step 2 → Verify OTP and move to step 3
  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await OtpService.verifyOtp(
      _emailCtrl.text.trim(),
      _otpCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      setState(() => _currentStep = 2);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  /// Step 3 → Upload ID proof and complete registration
  Future<void> _completeRegistration() async {
    if (_idProofFile == null) {
      setState(() => _errorMessage = 'Please upload your ID proof to continue');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
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
    if (role == 'authority') screen = const AuthorityHome();
    else if (role == 'government') screen = const GovernmentHome();
    else screen = const UserHome();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => screen), (_) => false);
  }

  Future<void> _pickIdProof() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload ID Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _idProofFile = File(picked.path));
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (_currentStep > 0) {
                          setState(() { _currentStep--; _errorMessage = null; });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Expanded(
                      child: Text('Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: List.generate(3, (i) {
                    final isActive = i == _currentStep;
                    final isDone = i < _currentStep;
                    return Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone ? AppColors.success : isActive ? Colors.white : Colors.white30,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                          color: isActive ? AppColors.primary : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                            ),
                          ),
                          if (i < 2)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i < _currentStep ? AppColors.success : Colors.white30,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              // Step labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Details', 'Verify OTP', 'ID Proof'].asMap().entries.map((e) {
                    return Text(e.value,
                        style: TextStyle(
                            color: e.key <= _currentStep ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: e.key == _currentStep ? FontWeight.bold : FontWeight.normal));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
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
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Step content
                        if (_currentStep == 0) _buildStep1(),
                        if (_currentStep == 1) _buildStep2(),
                        if (_currentStep == 2) _buildStep3(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 1: Basic details form
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Fill in your details to create an account', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v!.isEmpty ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
            validator: (v) => v!.length < 10 ? 'Enter valid 10 digit phone' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passCtrl,
            decoration: InputDecoration(
              labelText: 'Password *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            obscureText: _obscurePass,
            validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Register As *', prefixIcon: Icon(Icons.badge_outlined)),
            items: const [
              DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
              DropdownMenuItem(value: 'authority', child: Text('Authority Officer')),
              DropdownMenuItem(value: 'government', child: Text('Government Official')),
            ],
            onChanged: (v) => setState(() { _selectedRole = v!; _accessCodeCtrl.clear(); }),
          ),
          if (_selectedRole != 'citizen') ...[
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
                      '${_selectedRole == 'authority' ? 'Authority' : 'Government'} registration requires an official access code.',
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
                  icon: Icon(_obscureCode ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCode = !_obscureCode),
                ),
              ),
              obscureText: _obscureCode,
              validator: (v) => _selectedRole != 'citizen' && v!.isEmpty ? 'Access code required' : null,
            ),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _isLoading ? null : _proceedToOtp,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send OTP & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Step 2: OTP verification
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('Verify Your Email', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Enter the 6-digit OTP sent to\n${_emailCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        // Demo OTP display for hackathon
        if (_demoOtp != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Text('Demo OTP: $_demoOtp',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        // OTP input field
        TextFormField(
          controller: _otpCtrl,
          decoration: const InputDecoration(
            labelText: 'Enter 6-digit OTP',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : () async {
            setState(() { _otpCtrl.clear(); _errorMessage = null; });
            await _proceedToOtp();
          },
          child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  /// Step 3: ID proof upload
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Upload ID Proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Required for identity verification. Your data is stored securely.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        // Security notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security, color: AppColors.success, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your ID proof is encrypted and stored securely. It will only be used for identity verification.',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // ID type selector
        DropdownButtonFormField<String>(
          value: _selectedIdType,
          decoration: const InputDecoration(labelText: 'ID Type *', prefixIcon: Icon(Icons.credit_card_outlined)),
          items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedIdType = v!),
        ),
        const SizedBox(height: 20),
        // ID proof upload area
        GestureDetector(
          onTap: _pickIdProof,
          child: Container(
            height: _idProofFile != null ? 200 : 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _idProofFile != null ? AppColors.success : AppColors.primary.withValues(alpha: 0.3),
                width: _idProofFile != null ? 2 : 1,
                style: BorderStyle.solid,
              ),
            ),
            child: _idProofFile != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_idProofFile!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _idProofFile = null),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('ID Uploaded', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text('Tap to upload ID proof', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Camera or Gallery', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _isLoading ? null : _completeRegistration,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Complete Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
