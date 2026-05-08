import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';

import 'custom_input_decoration.dart';

class RoleDropdown extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String?> onChanged;

  const RoleDropdown({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  static const List<String> _roles = [
    'Quality Manager',
    'Internal Auditor',
    'Auditee',
    'Admin',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedRole,

      decoration: customInputDecoration(
        hint: '',
        icon: Icons.person_outline,
      ),

      items: _roles.map((role) {
        final bool isEnabled = role == 'Quality Manager';

        return DropdownMenuItem<String>(
          value: role,
          enabled: isEnabled,

          child: Text(
            role,
            style: TextStyle(
              color: isEnabled ? Colors.black : AppColors.textDisabled,
            ),
          ),
        );
      }).toList(),

      onChanged: (val) {
        if (val == 'Quality Manager') {
          onChanged(val);
        }
      },
    );
  }
}