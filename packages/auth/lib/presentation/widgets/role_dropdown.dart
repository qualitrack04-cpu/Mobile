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
      initialValue: selectedRole,
      decoration: customInputDecoration(
        hint: '',
        icon: Icons.person_outline,
      ),
      items: const [
        DropdownMenuItem(
          value: 'QualityManager', // value = format backend
          child: Text('Quality Manager'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}