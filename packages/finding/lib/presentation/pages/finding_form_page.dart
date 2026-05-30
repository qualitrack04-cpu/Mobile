import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FindingFormPage extends StatefulWidget {
  final String? initialDepartment;
  final String? auditorName;
  final String? clauseRef;
  final String? sessionId;          // ✅ TAMBAH
  final String? checklistItemId;    // ✅ TAMBAH

  const FindingFormPage({
    super.key,
    this.initialDepartment,
    this.auditorName,
    this.clauseRef,
    this.sessionId,          // ✅ TAMBAH
    this.checklistItemId,    // ✅ TAMBAH
  });

  @override
  State<FindingFormPage> createState() => _FindingFormPageState();
}

class _FindingFormPageState extends State<FindingFormPage> {
  final _titleController = TextEditingController();
  final _reporterController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedDepartment;
  FindingCategory _selectedCategory = FindingCategory.majorNC;
  final List<XFile> _evidenceImages = [];
  final ImagePicker _picker = ImagePicker();

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
      _reporterController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedDepartment != null;

  final Map<String, String> _departmentMap = {
    'Production': 'Produksi',
    'Warehouse': 'Warehouse',
    'Quality Control': 'QC',
    'Packaging': 'Packaging'
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialDepartment != null) {
      String? matchedKey = _departmentMap.entries
          .where((e) => e.value == widget.initialDepartment)
          .map((e) => e.key)
          .firstOrNull;
          
      if (matchedKey != null) {
        _selectedDepartment = matchedKey;
      } else {
        _departmentMap[widget.initialDepartment!] = widget.initialDepartment!;
        _selectedDepartment = widget.initialDepartment;
      }
    }
    // Selalu isi reporter dengan auditorName jika tersedia
    if (widget.auditorName != null && widget.auditorName!.isNotEmpty) {
      _reporterController.text = widget.auditorName!;
    }
    _titleController.addListener(() => setState(() {}));
    _reporterController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reporterController.dispose();
    super.dispose();
  }

  // ✅ Tampilkan pilihan: Kamera atau Galeri
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

  // ✅ Ambil satu gambar dari kamera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (image != null) {
        setState(() {
          _evidenceImages.add(image);
        });
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

  // ✅ Ambil banyak gambar sekaligus dari galeri
  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (images.isNotEmpty) {
        setState(() {
          _evidenceImages.addAll(images);
        });
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

  // ✅ Hapus gambar dari list
  void _removeImage(int index) {
    setState(() {
      _evidenceImages.removeAt(index);
    });
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
          'Create Findings',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: BlocConsumer<FindingBloc, FindingState>(
        listener: (context, state) {
          if (state is FindingCreated) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Finding successfully created!'),
                backgroundColor: Colors.green,
              ),
            );
            // Pop dengan Finding object agar pemanggil (checklist / finding list)
            // bisa menyimpan / me-refresh data yang baru dibuat.
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
                        hint: 'Enter the finding title...',
                      ),
                      _buildReporterField(),
                      _buildDivider(),
                      _buildCategoryDropdown(),
                      _buildDivider(),
                      _buildDepartmentDropdown(),
                      _buildDivider(),
                      _buildTextField(
                        label: 'DESCRIPTION',
                        controller: _descriptionController,
                        hint: 'Detail the non-conformance observed during the audit...',
                        maxLines: 5,
                      ),
                      _buildDivider(),
                      _buildEvidenceSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSubmitButton(context, state),
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

  /// Jika dipanggil dari audit checklist (auditorName tersedia),
  /// tampilkan reporter sebagai read-only terkunci.
  /// Jika dari halaman standalone, tampilkan sebagai field yang bisa diedit.
  Widget _buildReporterField() {
    final isLocked = widget.auditorName != null && widget.auditorName!.isNotEmpty;

    if (isLocked) {
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

    return _buildTextField(
      label: 'REPORTER',
      controller: _reporterController,
      hint: 'Enter the reporter name...',
    );
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
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5)),
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
          const Text('CATEGORY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5)),
          DropdownButtonHideUnderline(
            child: DropdownButton<FindingCategory>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              items: categories.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
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
    // Jika department sudah diset dari audit checklist, tampilkan sebagai read-only
    if (widget.initialDepartment != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DEPARTMENT',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDepartment ?? widget.initialDepartment!,
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

    // Jika bukan dari audit checklist, tampilkan dropdown biasa
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEPARTMENT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              hint: const Text('Select Department',
                  style: TextStyle(color: Colors.black26, fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              items: _departmentMap.keys.map((deptKey) {
                return DropdownMenuItem(
                  value: deptKey,
                  child: Text(deptKey,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDepartment = value),
            ),
          ),
        ],
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
              const Text('EVIDENCE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5)),
              Text('${_evidenceImages.length} photo',
                  style: const TextStyle(fontSize: 11, color: Colors.black38)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // ✅ Tampilkan gambar asli dari device
              ..._evidenceImages.asMap().entries.map((entry) {
                return _buildImageThumbnail(entry.value, entry.key, itemSize);
              }),
              // Tombol tambah gambar
              _buildAddImageButton(itemSize),
            ],
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
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
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

  // ✅ Thumbnail gambar nyata dengan tombol hapus
  Widget _buildImageThumbnail(XFile image, int index, double size) {
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
        // Tombol hapus (X) di pojok kanan atas
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
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

  // ✅ Tombol tambah gambar → buka dialog pilih sumber
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
            Text('Add Image',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, FindingState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (state is FindingLoading || !_isFormValid)
            ? null
            : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          disabledBackgroundColor: const Color(0xFF0D2B55).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: state is FindingLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Submit Findings',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.send, color: Colors.white, size: 18),
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
          backgroundColor: Colors.orange));
      return;
    }
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Department cannot be empty!'),
          backgroundColor: Colors.orange));
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Description cannot be empty!'),
          backgroundColor: Colors.orange));
      return;
    }

    context.read<FindingBloc>().add(
          CreateFindingEvent(
            category: _selectedCategory,
            description: _descriptionController.text,
            clauseRef: _titleController.text,
            department: _departmentMap[_selectedDepartment] ?? _selectedDepartment!,
            reporter: _reporterController.text,
            sessionId: widget.sessionId,           // ✅ TAMBAH
            checklistItemId: widget.checklistItemId, // ✅ TAMBAH
            evidencePaths: _evidenceImages.map((e) => e.path).toList(),
          ),
        );
  }
}