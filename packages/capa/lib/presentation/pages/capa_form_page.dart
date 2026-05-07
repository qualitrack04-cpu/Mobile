import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';
import 'package:capa/presentation/bloc/capa_state.dart';

class CapaFormPage extends StatefulWidget {
  final String? findingId;

  const CapaFormPage({super.key, this.findingId});

  @override
  State<CapaFormPage> createState() => _CapaFormPageState();
}

class _CapaFormPageState extends State<CapaFormPage> {
  final _rootCauseController = TextEditingController();
  final _correctiveActionController = TextEditingController();
  final _preventiveActionController = TextEditingController();
  final _picController = TextEditingController();
  DateTime? _selectedDeadline;

  @override
  void dispose() {
    _rootCauseController.dispose();
    _correctiveActionController.dispose();
    _preventiveActionController.dispose();
    _picController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D2B55)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QualiTrack',
          style: TextStyle(
            color: Color(0xFF0D2B55),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocConsumer<CapaBloc, CapaState>(
        listener: (context, state) {
          if (state is CapaCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CAPA berhasil disimpan!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
          if (state is CapaError) {
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
                  'CAPA Form',
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
                      // Root Cause
                      _buildTextField(
                        label: 'PROBLEM TITLE',
                        controller: _rootCauseController,
                        hint: 'Describe the root cause...',
                        maxLines: 3,
                      ),
                      _buildDivider(),

                      // Finding ID
                      _buildTextField(
                        label: 'FINDING',
                        controller: TextEditingController(
                          text: widget.findingId ?? '',
                        ),
                        hint: 'Finding ID...',
                        enabled: widget.findingId == null,
                      ),
                      _buildDivider(),

                      // Corrective Action
                      _buildTextField(
                        label: 'ACTION',
                        controller: _correctiveActionController,
                        hint: 'Detail the non-conformance observed during the audit...',
                        maxLines: 4,
                      ),
                      _buildDivider(),

                      // Person in Charge
                      _buildTextField(
                        label: 'PERSON IN CHARGE',
                        controller: _picController,
                        hint: 'e.g., Amir Oakwood',
                      ),
                      _buildDivider(),

                      // Date picker
                      _buildDateField(context),
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
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            enabled: enabled,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
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

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDeadline = picked);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDeadline != null
                      ? '${_selectedDeadline!.day} ${_getMonth(_selectedDeadline!.month)} ${_selectedDeadline!.year}'
                      : 'Pilih tanggal deadline...',
                  style: TextStyle(
                    fontSize: 15,
                    color: _selectedDeadline != null
                        ? Colors.black87
                        : Colors.black26,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, CapaState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: state is CapaLoading ? null : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          disabledBackgroundColor: const Color(0xFF0D2B55).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: state is CapaLoading
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
          state is CapaLoading ? 'Menyimpan...' : 'Submit CAPA',
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
    if (_rootCauseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem Title tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_correctiveActionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_picController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Person In Charge tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<CapaBloc>().add(
          CreateCapaEvent(
            findingId: widget.findingId ?? '',
            rootCause: _rootCauseController.text,
            correctiveAction: _correctiveActionController.text,
            preventiveAction: _preventiveActionController.text,
            picId: _picController.text,
            deadline: _selectedDeadline!,
          ),
        );
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}