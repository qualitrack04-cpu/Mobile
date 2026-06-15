import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:get_it/get_it.dart';
import 'package:finding/data/datasources/finding_remote_datasource.dart';
import 'package:core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FindingEditPage extends StatefulWidget {
  final Finding finding;
  final bool lockFields;

  const FindingEditPage({
    super.key,
    required this.finding,
    this.lockFields = false,
  });

  @override
  State<FindingEditPage> createState() => _FindingEditPageState();
}

class _FindingEditPageState extends State<FindingEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _reporterController;
  String? _selectedDepartment;
  late FindingCategory _selectedCategory;

  // Evidence baru dari device (lokal)
  final List<XFile> _evidenceImages = [];
  final ImagePicker _picker = ImagePicker();

  // ✅ Evidence lama dari server — simpan sebagai state supaya bisa hapus reaktif
  List<Map<String, String>> _existingEvidences = [];
  bool _evidencesLoading = true;
  int _originalEvidenceCount = 0; // ← tracking jumlah awal untuk _isDirty

  // ✅ Tracking fileId yang sedang dihapus (supaya bisa tampilkan loading per item)
  final Set<String> _deletingIds = {};

  final Map<String, String> _departmentMap = {
    'Production': 'Produksi',
    'Warehouse': 'Warehouse',
    'Quality Control': 'QC',
    'Packaging': 'Packaging'
  };

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.finding.clauseRef)
          ..addListener(() => setState(() {}));
    _descriptionController =
        TextEditingController(text: widget.finding.description)
          ..addListener(() => setState(() {}));
    _reporterController =
        TextEditingController(text: widget.finding.reporter)
          ..addListener(() => setState(() {}));
    _selectedCategory = widget.finding.category;

    String deptValue = widget.finding.department;
    String? matchedKey = _departmentMap.entries
        .where((e) => e.value == deptValue)
        .map((e) => e.key)
        .firstOrNull;
    
    if (matchedKey != null) {
      _selectedDepartment = matchedKey;
    } else {
      _departmentMap[deptValue] = deptValue;
      _selectedDepartment = deptValue;
    }

    // ✅ Load evidence ke state (bukan Future) supaya bisa di-update saat hapus
    _loadExistingEvidences();
  }

  Future<void> _loadExistingEvidences() async {
    try {
      final evidences = await GetIt.instance<FindingRemoteDatasource>()
          .getEvidences(widget.finding.id);
      if (mounted) {
        setState(() {
          _existingEvidences = evidences;
          _originalEvidenceCount = evidences.length; // ← simpan jumlah awal
          _evidencesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _evidencesLoading = false);
    }
  }

  // ✅ Hapus evidence dari server lalu update UI
  Future<void> _deleteExistingEvidence(String fileId) async {
    setState(() => _deletingIds.add(fileId));
    try {
      await GetIt.instance<FindingRemoteDatasource>().deleteEvidence(fileId);
      if (mounted) {
        setState(() {
          _existingEvidences.removeWhere((e) => e['id'] == fileId);
          _deletingIds.remove(fileId);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deletingIds.remove(fileId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete evidence. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reporterController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tambah Evidence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B55),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2F7),
                  child: Icon(Icons.camera_alt, color: Color(0xFF0D2B55)),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2F7),
                  child: Icon(Icons.photo_library, color: Color(0xFF0D2B55)),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (image != null) {
        setState(() => _evidenceImages.add(image));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (images.isNotEmpty) {
        setState(() => _evidenceImages.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() => _evidenceImages.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Findings',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: BlocConsumer<FindingBloc, FindingState>(
        listener: (context, state) {
          if (state is FindingUpdated) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Finding successfully updated!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, state.finding);
          }
          if (state is FindingError) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: 'TITLE',
                        controller: _titleController,
                        hint: 'Masukkan judul finding...',
                      ),
                      _buildDivider(),
                      _buildReporterField(),
                      _buildDivider(),
                      _buildCategoryDropdown(),
                      _buildDivider(),
                      _buildDepartmentField(),
                      _buildDivider(),
                      _buildTextField(
                        label: 'DESCRIPTION',
                        controller: _descriptionController,
                        hint:
                            'Detail the non-conformance observed during the audit...',
                        maxLines: 5,
                      ),
                      _buildDivider(),
                      _buildEvidenceSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildEditButton(context, state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE));

  Widget _buildReporterField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPORTER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _reporterController.text,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
            ],
          ),
        ],
      ),
    );
  }

  /// Department — read-only jika lockFields=true (dari audit checklist)
  Widget _buildDepartmentField() {
    if (widget.lockFields) {
      final displayDept = _departmentMap.entries
          .firstWhere(
            (e) => e.key == _selectedDepartment,
            orElse: () => MapEntry(_selectedDepartment ?? '', _selectedDepartment ?? ''),
          )
          .key;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEPARTMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayDept,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
              ],
            ),
          ],
        ),
      );
    }
    return _buildDepartmentDropdown();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = {
      FindingCategory.majorNC: 'Major NC',
      FindingCategory.minorNC: 'Minor NC',
      FindingCategory.ofi: 'OFI',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<FindingCategory>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              items: categories.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEPARTMENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              hint: const Text(
                'Select Department',
                style: TextStyle(color: Colors.black26, fontSize: 14),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              items: _departmentMap.keys.map((deptKey) {
                return DropdownMenuItem(
                  value: deptKey,
                  child: Text(
                    deptKey,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDepartment = value),
            ),
          ),
        ],
      ),
    );
  }

  void _showNetworkImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final double itemSize = ((screenWidth - 93) / 3).floorToDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EVIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${_existingEvidences.length + _evidenceImages.length} photo',
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Evidence lama dari server
          if (_evidencesLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_existingEvidences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _existingEvidences.map((evidence) {
                  final fileId = evidence['id']!;
                  final url = evidence['url']!;
                  final isDeleting = _deletingIds.contains(fileId);

                  return Stack(
                    children: [
                      // Thumbnail
                      GestureDetector(
                        onTap: isDeleting
                            ? null
                            : () => _showNetworkImageDialog(context, url),
                        child: Container(
                          width: itemSize,
                          height: itemSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isDeleting
                                // ← Tampilkan loading saat sedang dihapus
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey[400],
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      // ✅ Tombol hapus (X merah) — hanya tampil kalau tidak sedang dihapus
                      if (!isDeleting)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _confirmDeleteEvidence(fileId),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

          // Evidence baru (lokal, belum diupload)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._evidenceImages.asMap().entries.map((entry) {
                return _buildNewImageThumbnail(entry.value, entry.key, itemSize);
              }),
              _buildAddImageButton(itemSize),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Konfirmasi sebelum hapus supaya tidak tidak sengaja terhapus
  void _confirmDeleteEvidence(String fileId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Hapus Evidence?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Evidence ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteExistingEvidence(fileId);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewImageThumbnail(XFile image, int index, double size) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showImageDialog(context, image.path),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(image.path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(double size) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey[600], size: 28),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isDirty {
    return _titleController.text != widget.finding.clauseRef ||
        _descriptionController.text != widget.finding.description ||
        _reporterController.text != widget.finding.reporter ||
        _selectedCategory != widget.finding.category ||
        _selectedDepartment != widget.finding.department && _departmentMap[_selectedDepartment] != widget.finding.department ||
        _evidenceImages.isNotEmpty ||
        _existingEvidences.length != _originalEvidenceCount; // ← evidence dihapus
  }

  Widget _buildEditButton(BuildContext context, FindingState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (state is FindingLoading || !_isDirty)
            ? null
            : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          disabledBackgroundColor: const Color(0xFF0D2B55).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state is FindingLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Edit Findings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.edit, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Title cannot be empty!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Description cannot be empty!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    context.read<FindingBloc>().add(
          UpdateFindingEvent(
            id: widget.finding.id,
            category: _selectedCategory,
            description: _descriptionController.text,
            clauseRef: _titleController.text,
            department: _departmentMap[_selectedDepartment] ?? _selectedDepartment!,
            reporter: _reporterController.text,
            reporterId: widget.finding.reporterId,
            evidencePaths: _evidenceImages.map((e) => e.path).toList(),
          ),
        );
  }
}