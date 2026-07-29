import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../constants/countries.dart';

/// Champ de saisie de numero de telephone premium avec selecteur de pays
/// (drapeau + indicatif international) et une feuille de recherche modale
/// chargeant tous les pays.
class SicPhoneField extends StatefulWidget {
  const SicPhoneField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '64 59 82 58',
    this.validator,
    this.onCountryChanged,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
    this.defaultCountryCode = 'BF',
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<Country>? onCountryChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final String defaultCountryCode;
  final String? helperText;

  @override
  State<SicPhoneField> createState() => _SicPhoneFieldState();
}

class _SicPhoneFieldState extends State<SicPhoneField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  bool _focused = false;
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
    // Definir le pays par defaut (Burkina Faso par defaut)
    _selectedCountry = allCountries.firstWhere(
      (c) => c.code == widget.defaultCountryCode,
      orElse: () => allCountries.first,
    );
  }

  void _onFocusChange() {
    if (_focused != _node.hasFocus) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    if (!widget.enabled) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CountryPickerSheet(
          initialCountry: _selectedCountry,
          onSelect: (country) {
            setState(() {
              _selectedCountry = country;
            });
            widget.onCountryChanged?.call(country);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          style: AppTextStyles.microLabel.copyWith(
            color: _focused ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _node,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
            ],
            onFieldSubmitted: widget.onSubmitted,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              prefixIcon: InkWell(
                onTap: _showCountryPicker,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.network(
                          'https://flagcdn.com/w40/${_selectedCountry.code.toLowerCase()}.png',
                          width: 24,
                          height: 16,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            _selectedCountry.flag,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      // Séparateur vertical comme sur l'interface cible
                      Container(
                        width: 1,
                        height: 22,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.initialCountry,
    required this.onSelect,
  });

  final Country initialCountry;
  final ValueChanged<Country> onSelect;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<Country> _filtered = allCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _search.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = allCountries;
      } else {
        _filtered = allCountries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.dialCode.contains(query) ||
              c.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7 + keyboardHeight,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Barre de glissement de la feuille
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Sélectionner un pays',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              autofocus: true,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Rechercher un pays ou code (+226...)',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textTertiary),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Liste des pays
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun pays trouvé',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final country = _filtered[index];
                      final isSelected =
                          country.code == widget.initialCountry.code;

                      return ListTile(
                        onTap: () {
                          widget.onSelect(country);
                          Navigator.pop(context);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            'https://flagcdn.com/w40/${country.code.toLowerCase()}.png',
                            width: 28,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              country.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        title: Text(
                          country.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country.dialCode,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
