import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:mobile/injector.dart';

class FindingFormPage extends StatefulWidget {
  const FindingFormPage({super.key});

  @override
  State<FindingFormPage> createState() => _FindingFormPageState();
}

class _FindingFormPageState extends State<FindingFormPage> {
  final _descriptionController = TextEditingController();
  final _clauseRefController = TextEditingController();
  FindingCategory _selectedCategory = FindingCategory.majorNC;
  final List<String> _evidenceImages = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    _clauseRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FindingBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Color(0xFF0D2B55)),
          title: const Text(
            'QualiTrack',
            style: TextStyle(
              color: Color(0xFF0D2B55),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocConsumer<FindingBloc, FindingState>(
          listener: (context, state) {
            if (state is FindingCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Finding berhasil disimpan!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
            if (state is FindingError) {
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
                  // Title
                  const Text(
                    'Findings Form',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        _buildCategoryField(),
                        _buildDivider(),

                        // Description
                        _buildDescriptionField(),
                        _buildDivider(),

                        // Clause Ref
                        _buildClauseRefField(),
                        _buildDivider(),

                        // Evidence
                        _buildEvidenceSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(context, state),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }

  Widget _buildCategoryField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
              items: FindingCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category.toBackendString(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Detail the non-conformance observed during the audit...',
              hintStyle: TextStyle(
                color: Colors.black26,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClauseRefField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLAUSE REF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _clauseRefController,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'e.g., ISO9001 8.1',
              hintStyle: TextStyle(
                color: Colors.black26,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Existing images
              ..._evidenceImages.map(
                (image) => _buildImageThumbnail(image),
              ),

              // Add Image Button
              _buildAddImageButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String image) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.white, size: 32),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () {
        // Nanti implement image picker
        setState(() {
          _evidenceImages.add('dummy_image_${_evidenceImages.length}');
        });
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[400]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey[600], size: 24),
            Text(
              'Add Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, FindingState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: state is FindingLoading ? null : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          disabledBackgroundColor: const Color(0xFF0D2B55).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: state is FindingLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send, color: Colors.white),
        label: Text(
          state is FindingLoading ? 'Menyimpan...' : 'Submit Finding',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_clauseRefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clause Ref tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<FindingBloc>().add(
          CreateFindingEvent(
            category: _selectedCategory,
            description: _descriptionController.text,
            clauseRef: _clauseRefController.text,
          ),
        );
  }
}