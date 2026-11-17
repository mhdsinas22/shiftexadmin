import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';

class CustomerSearchBarWidget extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClear;
  final String hintText;

  const CustomerSearchBarWidget({
    super.key,
    this.initialValue = '',
    required this.onSearchChanged,
    this.onClear,
    this.hintText = 'Search by name, +91 phone, or SHFT-ID',
  });

  @override
  CustomerSearchBarWidgetState createState() => CustomerSearchBarWidgetState();
}

class CustomerSearchBarWidgetState extends State<CustomerSearchBarWidget> {
  late final TextEditingController controller;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant CustomerSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != controller.text) {
      controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void onTextChanged(String value) {
    setState(() {});
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 350), () {
      widget.onSearchChanged(value.trim());
    });
  }

  void clearText() {
    controller.clear();
    setState(() {});
    debounceTimer?.cancel();
    widget.onSearchChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onTextChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.0,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onPressed: clearText,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
