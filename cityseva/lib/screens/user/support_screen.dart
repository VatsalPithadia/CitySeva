import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _expandedFaq;
  final _msgCtrl = TextEditingController();
  int _satisfactionRating = 0;
  bool _feedbackSubmitted = false;

  final _faqs = const [
    _Faq('How do I submit a complaint?',
        'Go to the Home tab → Fill in the complaint title, description, select department, add your location and photos → Tap Submit. You will receive a unique complaint ID.'),
    _Faq('How long does it take to resolve a complaint?',
        'Resolution time varies by department and issue severity. Typically 3–7 working days. You can track real-time status in the My Complaints tab.'),
    _Faq('Can I submit a complaint without a photo?',
        'Yes, photos are optional but highly recommended. They help authorities understand the issue faster and speed up resolution.'),
    _Faq('How will I know when my complaint is resolved?',
        'You will receive a push notification at every status change — Verified, Assigned, Work Started, and Completed.'),
    _Faq('Can I submit multiple complaints?',
        'Yes, you can submit as many complaints as needed. Each gets a unique ID and is tracked independently.'),
    _Faq('What if my complaint is rejected?',
        'If rejected, the authority will provide a reason. You can re-submit with more details or contact support if you believe it was wrongly rejected.'),
    _Faq('How is my data protected?',
        'Your personal data is used only for complaint processing and is never shared with third parties. We follow strict data privacy guidelines.'),
    _Faq('Can I edit a complaint after submitting?',
        'Currently complaints cannot be edited after submission. If you made an error, contact support with your complaint ID.'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'FAQs'),
            Tab(text: 'Contact Us'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildContactTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Text('🙋', style: TextStyle(fontSize: 32)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frequently Asked Questions',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Find quick answers to common questions',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_faqs.length, (i) {
          final expanded = _expandedFaq == i;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _expandedFaq = expanded ? null : i),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(_faqs[i].question,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                        ),
                        Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.primary),
                      ],
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Text(_faqs[i].answer,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        _contactCard(
          icon: Icons.email_outlined,
          color: AppColors.primary,
          title: 'Email Support',
          subtitle: 'support@cityseva.gov.in',
          actionLabel: 'Copy Email',
          onTap: () {
            Clipboard.setData(const ClipboardData(text: 'support@cityseva.gov.in'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email copied to clipboard'), backgroundColor: AppColors.success),
            );
          },
        ),
        const SizedBox(height: 12),
        _contactCard(
          icon: Icons.phone_outlined,
          color: AppColors.success,
          title: 'Helpline Number',
          subtitle: '1800-XXX-XXXX (Toll Free)',
          actionLabel: 'Copy Number',
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '1800XXXXXXX'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Number copied to clipboard'), backgroundColor: AppColors.success),
            );
          },
        ),
        const SizedBox(height: 12),
        _contactCard(
          icon: Icons.access_time_outlined,
          color: AppColors.warning,
          title: 'Support Hours',
          subtitle: 'Mon–Sat: 9:00 AM – 6:00 PM',
          actionLabel: null,
          onTap: null,
        ),
        const SizedBox(height: 24),
        const Text('Send a Message',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _msgCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Describe your issue or query in detail...',
            hintStyle: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            if (_msgCtrl.text.trim().isEmpty) return;
            _msgCtrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message sent! We will respond within 24 hours.'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String? actionLabel,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (actionLabel != null && onTap != null)
            TextButton(onPressed: onTap, child: Text(actionLabel, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
    if (_feedbackSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Thank you for your feedback!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Your response helps us improve CitySeva.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _feedbackSubmitted = false;
                _satisfactionRating = 0;
              }),
              child: const Text('Submit Another'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Text('💬', style: TextStyle(fontSize: 32)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App Satisfaction Survey',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Help us improve your experience',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text('How satisfied are you with CitySeva?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _emojiRating(1, '😞', 'Very Bad'),
            _emojiRating(2, '😕', 'Bad'),
            _emojiRating(3, '😐', 'Okay'),
            _emojiRating(4, '😊', 'Good'),
            _emojiRating(5, '😄', 'Excellent'),
          ],
        ),
        const SizedBox(height: 28),
        const Text('What can we improve?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...[
          'App Speed & Performance',
          'Complaint Tracking',
          'Notification System',
          'UI & Design',
          'Response Time by Authorities',
        ].map((item) => _CheckItem(label: item)),
        const SizedBox(height: 20),
        const Text('Additional Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        TextFormField(
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Share your thoughts...', hintStyle: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _satisfactionRating == 0
              ? null
              : () => setState(() => _feedbackSubmitted = true),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (_satisfactionRating == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Please select a satisfaction rating to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
      ],
    );
  }

  Widget _emojiRating(int value, String emoji, String label) {
    final selected = _satisfactionRating == value;
    return GestureDetector(
      onTap: () => setState(() => _satisfactionRating = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: selected ? 36 : 28)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _CheckItem extends StatefulWidget {
  final String label;
  const _CheckItem({required this.label});

  @override
  State<_CheckItem> createState() => _CheckItemState();
}

class _CheckItemState extends State<_CheckItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _checked,
      onChanged: (v) => setState(() => _checked = v ?? false),
      title: Text(widget.label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
