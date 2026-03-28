import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../services/image_verification_service.dart';
import '../../utils/app_theme.dart';
import 'complaint_detail.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  Department _selectedDept = Department.roadInfrastructure;
  List<File> _images = [];
  double? _lat, _lng;
  bool _fetchingLocation = false;
  bool _submitting = false;
  bool _verifyingImages = false; // Image verification state
  List<ImageVerificationResult> _imageVerificationResults = [];
  List<Complaint> _similarComplaints = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission denied. Please enable in settings.');
        setState(() => _fetchingLocation = false);
        return;
      }

      // Try with medium accuracy + 8 second timeout first
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        // Fallback: use last known position
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        _showSnack('Could not get location. Please try again.');
        setState(() => _fetchingLocation = false);
        return;
      }

      _lat = pos.latitude;
      _lng = pos.longitude;

      // Try reverse geocoding with 5 second timeout
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        ).timeout(const Duration(seconds: 5));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          _locationCtrl.text = parts.join(', ');
        } else {
          _locationCtrl.text =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        }
      } catch (_) {
        // Geocoding failed — just show coordinates
        _locationCtrl.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }

      _checkDuplicates();
    } catch (e) {
      _showSnack('Could not fetch location. Check GPS is enabled.');
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  void _checkDuplicates() {
    if (_lat == null || _lng == null) return;
    final similar = context.read<ComplaintProvider>().findSimilarComplaints(_selectedDept, _lat!, _lng!);
    setState(() => _similarComplaints = similar);
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
      _showSnack('Maximum 5 images allowed');
      return;
    }
    final picker = ImagePicker();
    final remaining = 5 - _images.length;
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= 5) {
      _showSnack('Maximum 5 images allowed');
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Verify images if any are uploaded
    if (_images.isNotEmpty) {
      setState(() => _verifyingImages = true);
      final results = await ImageVerificationService.verifyImages(_images);
      setState(() {
        _verifyingImages = false;
        _imageVerificationResults = results;
      });

      // Check if any image failed verification
      final failed = results.where((r) => !r.isReal).toList();
      if (failed.isNotEmpty) {
        // Show warning dialog — block submission if image is clearly fake
        final proceed = await _showImageVerificationDialog(results);
        if (!proceed) return;
      }
    }

    setState(() => _submitting = true);
    final id = await context.read<ComplaintProvider>().submitComplaint(
          title: _selectedDept.label, // Auto-title from department
          description: 'Reported via CitySeva app', // Default description
          department: _selectedDept,
          address: _locationCtrl.text.trim(),
          latitude: _lat ?? 0.0,
          longitude: _lng ?? 0.0,
          imagePaths: _images.map((f) => f.path).toList(),
        );
    setState(() => _submitting = false);
    if (!mounted) return;
    _showSuccessDialog(id);
  }

  /// Show image verification result dialog
  Future<bool> _showImageVerificationDialog(List<ImageVerificationResult> results) async {
    final failed = results.where((r) => !r.isReal).length;
    final warned = results.where((r) => r.warning && r.isReal).length;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(failed > 0 ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: failed > 0 ? AppColors.error : AppColors.warning),
                const SizedBox(width: 8),
                const Text('Image Verification', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed > 0
                      ? '$failed image(s) may be AI-generated or not real photos.'
                      : '$warned image(s) could not be fully verified.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...results.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            e.value.isReal ? (e.value.warning ? Icons.warning_outlined : Icons.check_circle_outline) : Icons.cancel_outlined,
                            color: e.value.isReal ? (e.value.warning ? AppColors.warning : AppColors.success) : AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Image ${e.key + 1}: ${e.value.reason}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                if (failed > 0) ...
                  [const SizedBox(height: 8),
                  const Text('Please use your camera to take real photos of the issue.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary))],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Re-upload Images'),
              ),
              if (warned > 0 && failed == 0)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Submit Anyway'),
                ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Complaint Submitted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Your complaint ID: ${id.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('You can track the status in My Complaints.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('New Complaint'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final complaint = context.read<ComplaintProvider>().complaints.firstWhere((c) => c.id == id);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: complaint)));
            },
            child: const Text('Track Status'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    setState(() {
      _images = [];
      _lat = null;
      _lng = null;
      _similarComplaints = [];
      _selectedDept = Department.roadInfrastructure;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Issue Details', Icons.report_problem_outlined),
            const SizedBox(height: 12),
            _buildDepartmentDropdown(),
            const SizedBox(height: 24),
            _buildSectionHeader('Location', Icons.location_on_outlined),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Address *',
                hintText: 'Enter area, street, city...',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.trim().isEmpty ? 'Please enter or fetch location' : null,
              onChanged: (_) {
                // If user types manually, clear GPS coords so they know
                if (_lat != null) {
                  setState(() {
                    _lat = null;
                    _lng = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _fetchingLocation ? null : _getCurrentLocation,
                icon: _fetchingLocation
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(_fetchingLocation ? 'Fetching Location...' : 'Use Current Location (GPS)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or type manually', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 8),
            // Manual location quick chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _locationChip('Near Home'),
                _locationChip('Office Area'),
                _locationChip('Market Area'),
                _locationChip('Main Road'),
                _locationChip('Colony'),
              ],
            ),
            if (_lat != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                      style: const TextStyle(color: AppColors.success, fontSize: 12)),
                ],
              ),
            ] else if (_locationCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.edit_location_alt_outlined, color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  const Text('Manual address entered (no GPS)',
                      style: TextStyle(color: AppColors.warning, fontSize: 12)),
                ],
              ),
            ],
            if (_similarComplaints.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAIDuplicateWarning(),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader('Photos (${_images.length}/5)', Icons.photo_camera_outlined),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitting || _verifyingImages ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
              child: _verifyingImages
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Verifying Images...', style: TextStyle(fontSize: 15, color: Colors.white)),
                      ],
                    )
                  : _submitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text('Submit Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _locationChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: const Icon(Icons.add_location_alt_outlined, size: 14),
      backgroundColor: AppColors.primary.withValues(alpha: 0.07),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      onPressed: () {
        final current = _locationCtrl.text.trim();
        if (current.isEmpty) {
          _locationCtrl.text = label;
        } else if (!current.contains(label)) {
          _locationCtrl.text = '$current, $label';
        }
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<Department>(
      initialValue: _selectedDept,
      decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.business_outlined)),
      items: Department.values.map((d) {
        return DropdownMenuItem(
          value: d,
          child: Row(
            children: [
              Text(d.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(d.label),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        setState(() => _selectedDept = v!);
        _checkDuplicates();
      },
    );
  }

  Widget _buildAIDuplicateWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Text('AI Alert: Similar Issue Detected', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_similarComplaints.length} similar complaint(s) already reported nearby for ${_selectedDept.label}.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ..._similarComplaints.take(2).map((c) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: c))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(c.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _statusColor(c.status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(c.status.label, style: TextStyle(fontSize: 10, color: _statusColor(c.status), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          const Text('You can still submit if it\'s a different issue.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (_, i) => Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: FileImage(_images[i]), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_images.isNotEmpty) const SizedBox(height: 12),
        if (_images.length < 5)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Color _statusColor(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.submitted: return AppColors.primary;
      case ComplaintStatus.verified: return AppColors.accent;
      case ComplaintStatus.assigned: return AppColors.warning;
      case ComplaintStatus.workStarted: return Colors.orange;
      case ComplaintStatus.completed: return AppColors.success;
      case ComplaintStatus.rejected: return AppColors.error;
    }
  }
}
