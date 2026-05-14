import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:core_services/services/api_service.dart';
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _actionController = TextEditingController();
  DateTime? _selectedDeadline;
  String? _selectedFindingId;
  String? _selectedPicId;

  // Data dari backend
  List<Map<String, String>> _findings = [];
  List<Map<String, String>> _users = [];
  bool _isLoadingData = true;
  String? _loadError;

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
          _selectedFindingId != null &&
          _actionController.text.trim().isNotEmpty &&
          _selectedPicId != null &&
          _selectedDeadline != null;

  @override
  void initState() {
    super.initState();
    if (widget.findingId != null) {
      _selectedFindingId = widget.findingId;
    }
    _titleController.addListener(() => setState(() {}));
    _actionController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });
    try {
      final api = GetIt.instance<ApiService>();

      // Load findings: GET /api/Finding
      final fRes = await api.client.get('/api/Finding');
      final findingsRaw = fRes.data as List<dynamic>;

      // Load semua users untuk PIC: GET /api/Auth/auditors (karena /users tidak ada)
      final uRes = await api.client.get('/api/Auth/auditors');
      final usersRaw = uRes.data['data'] as List<dynamic>;

      setState(() {
        _findings = findingsRaw.map((f) {
          final clause = f['clauseRef'] as String? ?? '';
          final desc = f['description'] as String? ?? '';
          final label = clause.isNotEmpty ? '$clause - $desc' : desc;
          return {
            'id': f['id'] as String,
            'title': label,
          };
        }).toList();

        _users = usersRaw.map((u) => {
          'id': u['id'] as String,
          'name': u['fullName'] as String,
        }).toList();

        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _loadError = 'Gagal memuat data: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _actionController.dispose();
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
          // Tampilkan error banner jika gagal load data
          return Column(
            children: [
              if (_loadError != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loadError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('Coba lagi', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
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
                            _buildTextField(
                              label: 'TITLE',
                              controller: _titleController,
                              hint: 'My name is Amir',
                            ),
                            _buildDivider(),
                            _buildFindingDropdown(),
                            _buildDivider(),
                            _buildTextField(
                              label: 'DESCRIPTION',
                              controller: _descriptionController,
                              hint: 'Detail the non-conformance observed during the audit...',
                              maxLines: 4,
                            ),
                            _buildDivider(),
                            _buildTextField(
                              label: 'ACTION',
                              controller: _actionController,
                              hint: 'Detail the non-conformance observed during the audit...',
                              maxLines: 4,
                            ),
                            _buildDivider(),
                            _buildPicDropdown(),
                            _buildDivider(),
                            _buildDateField(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSubmitButton(context, state),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
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
          _isLoadingData
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black38),
                ),
                SizedBox(width: 10),
                Text('Memuat...', style: TextStyle(color: Colors.black38, fontSize: 14)),
              ],
            ),
          )
              : _findings.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Text('Tidak ada finding tersedia', style: TextStyle(color: Colors.black45, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: _loadData,
                  child: const Text('Refresh', style: TextStyle(color: Colors.blue, fontSize: 13)),
                ),
              ],
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFindingId,
              isExpanded: true,
              hint: const Text('Select Finding', style: TextStyle(color: Colors.black26, fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              items: _findings.map((finding) {
                return DropdownMenuItem(
                  value: finding['id'],
                  child: Text(
                    finding['title']!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
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

  Widget _buildPicDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSON IN CHARGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          _isLoadingData
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black38),
                ),
                SizedBox(width: 10),
                Text('Memuat...', style: TextStyle(color: Colors.black38, fontSize: 14)),
              ],
            ),
          )
              : _users.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Text('Tidak ada user tersedia', style: TextStyle(color: Colors.black45, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: _loadData,
                  child: const Text('Refresh', style: TextStyle(color: Colors.blue, fontSize: 13)),
                ),
              ],
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPicId,
              isExpanded: true,
              hint: const Text('Select Person In Charge', style: TextStyle(color: Colors.black26, fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              items: _users.map((user) {
                return DropdownMenuItem(
                  value: user['id'],
                  child: Text(
                    user['name']!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPicId = value);
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
                    color: _selectedDeadline != null ? Colors.black87 : Colors.black26,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, color: Colors.black54, size: 20),
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
        onPressed: (state is CapaLoading || !_isFormValid)
            ? null
            : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          disabledBackgroundColor: const Color(0xFF0D2B55).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: state is CapaLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Submit CAPA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.send, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (_titleController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title minimal 5 karakter!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedFindingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding harus dipilih!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_actionController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action minimal 5 karakter!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedPicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Person In Charge harus dipilih!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline tidak boleh kosong!'), backgroundColor: Colors.orange),
      );
      return;
    }

    context.read<CapaBloc>().add(
      CreateCapaEvent(
        findingId: _selectedFindingId!,
        rootCause: _titleController.text.trim(),
        correctiveAction: _actionController.text.trim(),
        preventiveAction: _descriptionController.text.trim(),
        picId: _selectedPicId!,
        deadline: _selectedDeadline!,
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}