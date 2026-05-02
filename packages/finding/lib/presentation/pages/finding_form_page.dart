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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      children: [
                        // Category
                        _buildCategoryField(),
                        const Divider(height: 1),

                        // Description
                        _buildDescriptionField(),
                        const Divider(height: 1),

                        // Clause Ref
                        _buildClauseRefField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: state is FindingLoading
                          ? null
                          : () => _onSubmit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2B55),
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
                        state is FindingLoading
                            ? 'Menyimpan...'
                            : 'Submit Finding',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<FindingCategory>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'CATEGORY',
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          border: InputBorder.none,
        ),
        items: FindingCategory.values.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category.toBackendString()),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedCategory = value);
          }
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'DESCRIPTION',
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          hintText: 'Detail the non-conformance observed during the audit...',
          hintStyle: TextStyle(color: Colors.black26),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildClauseRefField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: _clauseRefController,
        decoration: const InputDecoration(
          labelText: 'CLAUSE REF',
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          hintText: 'e.g., ISO9001 8.1',
          hintStyle: TextStyle(color: Colors.black26),
          border: InputBorder.none,
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