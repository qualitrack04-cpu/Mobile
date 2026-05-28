import 'package:flutter/material.dart';
import 'custom_input_decoration.dart';

class RoleDropdown extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String?> onChanged;

  const RoleDropdown({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      decoration: customInputDecoration(
        hint: '',
        icon: Icons.person_outline,
      ),
      items: const [
        DropdownMenuItem(
          value: 'Admin',
          child: Text('Admin'),
        ),
        DropdownMenuItem(
          value: 'QualityManager',
          child: Text('Quality Manager'),
        ),
        DropdownMenuItem(
          value: 'AuditorInternal',
          child: Text('Auditor Internal'),
        ),
        DropdownMenuItem(
          value: 'Auditee',
          child: Text('Auditee'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}