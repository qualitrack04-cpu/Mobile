import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spc_card.dart';

/// Satuan yang bisa dipilih. Backend menerima string bebas, daftar ini
/// hanya untuk menyeragamkan input.
const List<String> kSpcUnits = [
  'mm',
  'g',
  'kg',
  'mL',
  'L',
  '°C',
  '%',
];

/// Kartu berisi seluruh isian parameter analisis.
///
/// Controller dikelola halaman, bukan widget ini, supaya halaman bisa
/// membaca nilainya saat submit tanpa perlu callback per field.
class SpcParameterForm extends StatelessWidget {
  const SpcParameterForm({
    super.key,
    required this.parameterNameController,
    required this.targetController,
    required this.lslController,
    required this.uslController,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.enabled = true,
  });

  final TextEditingController parameterNameController;
  final TextEditingController targetController;
  final TextEditingController lslController;
  final TextEditingController uslController;
  final String? selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _Section(
            label: 'PARAMETER NAME',
            child: TextFormField(
              controller: parameterNameController,
              enabled: enabled,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('e.g. Outer Diameter'),
              style: _inputStyle,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Parameter name wajib diisi'
                  : null,
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Section(
                    label: 'Target Value',
                    child: TextFormField(
                      controller: targetController,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [_numberFormatter],
                      decoration: _inputDecoration('0.00'),
                      style: _inputStyle,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return double.tryParse(value.trim()) == null
                            ? 'Angka tidak valid'
                            : null;
                      },
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: AppColors.borderLight,
                ),
                Expanded(
                  child: _Section(
                    label: 'Unit',
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      isExpanded: true,
                      decoration: _inputDecoration('Select Unit'),
                      style: _inputStyle,
                      hint: Text('Select Unit', style: _hintStyle),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                      items: kSpcUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit, style: _inputStyle),
                            ),
                          )
                          .toList(),
                      onChanged: enabled ? onUnitChanged : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Section(
                    label: 'LSL',
                    labelSuffix: '(Lower Spec Limit)',
                    child: TextFormField(
                      controller: lslController,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [_numberFormatter],
                      decoration: _inputDecoration('0.00'),
                      style: _inputStyle,
                      validator: _requiredNumber,
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: AppColors.borderLight,
                ),
                Expanded(
                  child: _Section(
                    label: 'USL',
                    labelSuffix: '(Upper Spec Limit)',
                    child: TextFormField(
                      controller: uslController,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [_numberFormatter],
                      decoration: _inputDecoration('0.00'),
                      style: _inputStyle,
                      validator: (value) {
                        final base = _requiredNumber(value);
                        if (base != null) return base;

                        // Aturan yang sama diperiksa backend. Diperiksa di
                        // sini juga supaya pengguna tidak perlu menunggu
                        // upload selesai hanya untuk ditolak.
                        final lsl = double.tryParse(lslController.text.trim());
                        final usl = double.parse(value!.trim());
                        if (lsl != null && lsl >= usl) {
                          return 'USL harus lebih besar dari LSL';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return double.tryParse(value.trim()) == null ? 'Angka tidak valid' : null;
  }

  static final _numberFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'));

  static final TextStyle _inputStyle = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.primary,
  );

  static final TextStyle _hintStyle = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textDisabled,
  );

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      errorStyle: GoogleFonts.inter(fontSize: 10),
    );
  }
}

/// Satu sel isian: label kecil di atas, field di bawahnya.
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.child,
    this.labelSuffix,
  });

  final String label;
  final String? labelSuffix;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              if (labelSuffix != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    labelSuffix!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}