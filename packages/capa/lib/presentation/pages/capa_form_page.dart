import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';
import 'package:capa/presentation/bloc/capa_state.dart';
import 'package:core/core.dart'; // ✅ dari core

class CapaFormPage extends StatefulWidget {
  final String? findingId;

  const CapaFormPage({super.key, this.findingId});

  @override
  State<CapaFormPage> createState() => _CapaFormPageState();
}

class _CapaFormPageState extends State<CapaFormPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _actionController = TextEditingController();
  final _picController = TextEditingController();
  DateTime? _selectedDeadline;
  String? _selectedFindingId;

  // Mock finding list untuk dropdown
  final List<Map<String, String>> _findings = [
    {'id': '1', 'title': 'ISO9001 8.1 - Prosedur tidak terdokumentasi'},
    {'id': '2', 'title': 'ISO9001 7.1.5 - Kalibrasi alat ukur'},
    {'id': '3', 'title': 'ISO9001 7.1.3 - Catatan pemeliharaan'},
    {'id': '4', 'title': 'ISO9001 8.4 - Pengecekan kualitas'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.findingId != null) {
      _selectedFindingId = widget.findingId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _actionController.dispose();
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
          'CAPA Form',
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
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Title
                      _buildTextField(
                        label: 'TITLE',
                        controller: _titleController,
                        hint: 'My name is Amir',
                      ),
                      _buildDivider(),

                      // Finding Dropdown
                      _buildFindingDropdown(),
                      _buildDivider(),

                      // Description
                      _buildTextField(
                        label: 'DESCRIPTION',
                        controller: _descriptionController,
                        hint:
                            'Detail the non-conformance observed during the audit...',
                        maxLines: 4,
                      ),
                      _buildDivider(),

                      // Action
                      _buildTextField(
                        label: 'ACTION',
                        controller: _actionController,
                        hint:
                            'Detail the non-conformance observed during the audit...',
                        maxLines: 4,
                      ),
                      _buildDivider(),

                      // Person In Charge
                      _buildTextField(
                        label: 'PERSON IN CHARGE',
                        controller: _picController,
                        hint: 'Amir Oakwood',
                      ),
                      _buildDivider(),

                      // Date
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
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE));
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

  Widget _buildFindingDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFindingId,
              isExpanded: true,
              hint: const Text(
                'Select Finding',
                style: TextStyle(color: Colors.black26, fontSize: 14),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
              items:
                  _findings.map((finding) {
                    return DropdownMenuItem(
                      value: finding['id'],
                      child: Text(
                        finding['title']!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => _selectedFindingId = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color:
                        _selectedDeadline != null
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
      child: ElevatedButton(
        onPressed: state is CapaLoading ? null : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          disabledBackgroundColor: const Color(0xFF0D2B55).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            state is CapaLoading
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
                      'Submit CAPA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.send, color: Colors.white), // ← icon di kanan
                  ],
                ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFindingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finding harus dipilih!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_actionController.text.isEmpty) {
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
        findingId: _selectedFindingId!,
        rootCause: _titleController.text,
        correctiveAction: _actionController.text,
        preventiveAction: _descriptionController.text,
        picId: _picController.text,
        deadline: _selectedDeadline!,
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
