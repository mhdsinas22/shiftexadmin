import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';

class RejectionReasonDialogWidget extends StatefulWidget {
  final CustomerEntity customer;
  final ValueChanged<String> onConfirmReject;

  const RejectionReasonDialogWidget({
    super.key,
    required this.customer,
    required this.onConfirmReject,
  });

  static Future<String?> show(
    BuildContext context, {
    required CustomerEntity customer,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => RejectionReasonDialogWidget(
        customer: customer,
        onConfirmReject: (reason) {
          Navigator.of(ctx).pop(reason);
        },
      ),
    );
  }

  @override
  RejectionReasonDialogWidgetState createState() =>
      RejectionReasonDialogWidgetState();
}

class RejectionReasonDialogWidgetState
    extends State<RejectionReasonDialogWidget> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController controller;

  final List<String> quickReasons = [
    'Incomplete documentation',
    'Invalid phone number',
    'Duplicate account detected',
    'Suspicious registration activity',
  ];

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (formKey.currentState?.validate() ?? false) {
      widget.onConfirmReject(controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              size: 22,
              color: AppColors.purered,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Reject Customer',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provide a valid reason for rejecting ${widget.customer.fullName}. This explanation will be recorded in the audit log.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Quick tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickReasons.map((reason) {
                  return ActionChip(
                    label: Text(
                      reason,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    onPressed: () {
                      setState(() {
                        controller.text = reason;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Text input
              TextFormField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.purered),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter or select a rejection reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purered,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text(
            'Reject Customer',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
