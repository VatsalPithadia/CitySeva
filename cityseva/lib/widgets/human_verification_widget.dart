import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Human Verification Widget
/// Uses math CAPTCHA + slide gesture to verify user is human
/// Works completely offline — no API needed
class HumanVerificationWidget extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback? onFailed;

  const HumanVerificationWidget({
    super.key,
    required this.onVerified,
    this.onFailed,
  });

  @override
  State<HumanVerificationWidget> createState() =>
      _HumanVerificationWidgetState();
}

class _HumanVerificationWidgetState extends State<HumanVerificationWidget>
    with SingleTickerProviderStateMixin {
  // Math CAPTCHA
  late int _num1;
  late int _num2;
  late String _operator;
  late int _correctAnswer;
  final _answerCtrl = TextEditingController();
  bool _mathVerified = false;
  bool _mathError = false;

  // Slide verification
  double _slideValue = 0.0;
  bool _slideVerified = false;
  bool _isVerified = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _generateMathQuestion();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _generateMathQuestion() {
    final rand = Random();
    _num1 = rand.nextInt(9) + 1;
    _num2 = rand.nextInt(9) + 1;
    final ops = ['+', '-', '×'];
    _operator = ops[rand.nextInt(ops.length)];
    switch (_operator) {
      case '+':
        _correctAnswer = _num1 + _num2;
        break;
      case '-':
        // Ensure positive result
        if (_num1 < _num2) {
          final temp = _num1;
          _num1 = _num2;
          _num2 = temp;
        }
        _correctAnswer = _num1 - _num2;
        break;
      case '×':
        _num1 = rand.nextInt(5) + 1;
        _num2 = rand.nextInt(5) + 1;
        _correctAnswer = _num1 * _num2;
        break;
      default:
        _correctAnswer = _num1 + _num2;
    }
  }

  void _verifyMath() {
    final entered = int.tryParse(_answerCtrl.text.trim());
    if (entered == _correctAnswer) {
      setState(() {
        _mathVerified = true;
        _mathError = false;
      });
    } else {
      setState(() => _mathError = true);
      _shakeController.forward(from: 0);
      _answerCtrl.clear();
      // Regenerate question after wrong answer
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _generateMathQuestion();
            _mathError = false;
          });
        }
      });
    }
  }

  void _onSlideComplete() {
    if (!_mathVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please solve the math question first'),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() => _slideValue = 0.0);
      return;
    }
    setState(() {
      _slideVerified = true;
      _isVerified = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onVerified();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: AppColors.success, size: 24),
            SizedBox(width: 10),
            Text('Human Verified',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.security, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Human Verification',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Anti-Bot',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1: Math CAPTCHA
          _buildStepLabel('Step 1', 'Solve the math question',
              _mathVerified ? AppColors.success : AppColors.primary),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    _mathError
                        ? sin(_shakeController.value * pi * 4) *
                            _shakeAnimation.value
                        : 0,
                    0),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mathVerified
                    ? AppColors.success.withValues(alpha: 0.06)
                    : _mathError
                        ? AppColors.error.withValues(alpha: 0.06)
                        : AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _mathVerified
                      ? AppColors.success.withValues(alpha: 0.3)
                      : _mathError
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: _mathVerified
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text('Correct!',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Row(
                      children: [
                        // Math question display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_num1 $_operator $_num2 = ?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Answer input
                        Expanded(
                          child: TextField(
                            controller: _answerCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '?',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: _mathError
                                        ? AppColors.error
                                        : AppColors.divider),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _verifyMath(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Check button
                        ElevatedButton(
                          onPressed: _verifyMath,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Icon(Icons.check, size: 20),
                        ),
                      ],
                    ),
            ),
          ),
          if (_mathError) ...[
            const SizedBox(height: 6),
            const Text('Wrong answer. Try again!',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ],

          const SizedBox(height: 20),

          // Step 2: Slide to verify
          _buildStepLabel(
              'Step 2',
              'Slide to confirm',
              _slideVerified
                  ? AppColors.success
                  : _mathVerified
                      ? AppColors.primary
                      : Colors.grey),
          const SizedBox(height: 12),
          _buildSlider(),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String step, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(step,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSlider() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _slideVerified
            ? AppColors.success.withValues(alpha: 0.1)
            : _mathVerified
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _slideVerified
              ? AppColors.success.withValues(alpha: 0.4)
              : _mathVerified
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background text
          if (!_slideVerified)
            Text(
              _mathVerified
                  ? '← Slide to verify →'
                  : 'Solve math question first',
              style: TextStyle(
                color: _mathVerified
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          if (_slideVerified)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user,
                    color: AppColors.success, size: 18),
                SizedBox(width: 6),
                Text('Verified!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          // Slider thumb
          if (!_slideVerified)
            Positioned(
              left: _slideValue,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!_mathVerified) return;
                  setState(() {
                    _slideValue = (_slideValue + details.delta.dx)
                        .clamp(0.0, MediaQuery.of(context).size.width - 120);
                  });
                },
                onHorizontalDragEnd: (_) {
                  final maxWidth =
                      MediaQuery.of(context).size.width - 120;
                  if (_slideValue >= maxWidth * 0.85) {
                    _onSlideComplete();
                  } else {
                    setState(() => _slideValue = 0.0);
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _mathVerified
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Show human verification as a bottom sheet
/// Returns true if verified, false if dismissed
Future<bool> showHumanVerification(BuildContext context) async {
  bool verified = false;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          HumanVerificationWidget(
            onVerified: () {
              verified = true;
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    ),
  );
  return verified;
}
