import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_bloc.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_event.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/presentation/bloc/points_to_cash_state.dart';
import 'package:shiftexadmin/features/settings/presentation/widgets/rate_matrix_cell_widget.dart';

class UpdatePointsToCashDialogWidget extends StatefulWidget {
  final PointsToCashBloc bloc;

  const UpdatePointsToCashDialogWidget({super.key, required this.bloc});

  static Future<void> show(
    BuildContext context, {
    required PointsToCashBloc bloc,
  }) {
    bloc.add(const PrepareRateUpdateModalRequested());
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<PointsToCashBloc>.value(
        value: bloc,
        child: UpdatePointsToCashDialogWidget(bloc: bloc),
      ),
    );
  }

  @override
  State<UpdatePointsToCashDialogWidget> createState() =>
      _UpdatePointsToCashDialogWidgetState();
}

class _UpdatePointsToCashDialogWidgetState
    extends State<UpdatePointsToCashDialogWidget> {
  late final TextEditingController _rateController;
  final TextEditingController _noteController = TextEditingController();
  DateTime? _initialEffectiveAt;
  int? _initialRateValue;

  static const List<int> _presetRates = [5, 10, 15, 20, 25, 50];

  @override
  void initState() {
    super.initState();
    final cfg = widget.bloc.state.config;
    _initialEffectiveAt = cfg?.effectiveAt;
    _initialRateValue = cfg?.pointsPerRupee;
    _rateController = TextEditingController(
      text: (cfg?.pointsPerRupee ?? 10).toString(),
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<PointsToCashBloc, PointsToCashState>(
      listenWhen: (previous, current) {
        final successArrived =
            current.successMessage != null &&
            current.successMessage!.isNotEmpty &&
            current.successMessage != previous.successMessage;
        return successArrived ||
            previous.draftPointsPerRupeeInput !=
                current.draftPointsPerRupeeInput;
      },
      listener: (context, state) {
        if (state.successMessage != null &&
            state.successMessage!.isNotEmpty &&
            (state.config?.effectiveAt != _initialEffectiveAt ||
                state.config?.pointsPerRupee != _initialRateValue ||
                _initialEffectiveAt == null)) {
          Navigator.of(context).pop();
          return;
        }
        if (_rateController.text != state.draftPointsPerRupeeInput) {
          _rateController.value = TextEditingValue(
            text: state.draftPointsPerRupeeInput,
            selection: TextSelection.collapsed(
              offset: state.draftPointsPerRupeeInput.length,
            ),
          );
        }
      },
      builder: (context, state) {
        final isUpdating = state.status == PointsToCashStatus.updating;
        final proposedPts = state.proposedPointsPerRupee;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 40),
            padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.currency_exchange_rounded,
                          size: 20,
                          color: AppColors.goldenYellow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Conversion Rate',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Central Points-to-INR rate across Admin & POS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isUpdating
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current vs Proposed Rate Comparison
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CURRENT RATE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${state.activePointsPerRupee} pts = ₹1.00',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'NEW RATE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.linkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  state.isProposedRateValid
                                      ? '$proposedPts pts = ₹1.00'
                                      : 'Invalid value',
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: state.isProposedRateValid
                                        ? AppColors.linkBlue
                                        : AppColors.purered,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Points per ₹1 Input
                  const Text(
                    'Points equal to ₹1.00',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rateController,
                    enabled: !isUpdating,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (value) {
                      widget.bloc.add(DraftPointsPerRupeeChanged(value));
                    },
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixText: '₹1.00 = ',
                      prefixStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      suffixText: 'PTS',
                      suffixStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                      hintText: '10',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                        borderSide: const BorderSide(
                          color: AppColors.linkBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetRates.map((preset) {
                      final isSelected = proposedPts == preset;
                      return ChoiceChip(
                        label: Text('$preset pts'),
                        selected: isSelected,
                        onSelected: isUpdating
                            ? null
                            : (_) {
                                widget.bloc.add(
                                  DraftPointsPerRupeeChanged('$preset'),
                                );
                              },
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.pureWhite
                              : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.darkNavy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.darkNavy
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (state.validationError != null &&
                      state.validationError!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.validationError!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purered,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Live Conversion Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'LIVE CONVERSION PREVIEW',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (state.isProposedRateValid &&
                                proposedPts != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '₹${PointsToCashConfigEntity.formatLiabilityPerPointFor(proposedPts)} / pt',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.linkBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RateMatrixCellWidget(
                                pointsLabel: '100 pts',
                                cashLabel: state.isProposedRateValid
                                    ? '₹${state.proposedInrFor(100).toStringAsFixed(2)}'
                                    : '--',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RateMatrixCellWidget(
                                pointsLabel: '1,000 pts',
                                cashLabel: state.isProposedRateValid
                                    ? '₹${state.proposedInrFor(1000).toStringAsFixed(2)}'
                                    : '--',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RateMatrixCellWidget(
                                pointsLabel: '5,000 pts',
                                cashLabel: state.isProposedRateValid
                                    ? '₹${state.proposedInrFor(5000).toStringAsFixed(2)}'
                                    : '--',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Optional Note
                  TextField(
                    controller: _noteController,
                    enabled: !isUpdating,
                    maxLines: 1,
                    onChanged: (value) {
                      widget.bloc.add(DraftRateNoteChanged(value));
                    },
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      labelText: 'Amendment Note (Optional)',
                      hintText: 'e.g. Festive adjustment or margin review',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  if (state.status == PointsToCashStatus.error &&
                      state.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        state.errorMessage,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purered,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Submit Action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.canSubmitRateUpdate
                          ? () {
                              FocusScope.of(context).unfocus();
                              widget.bloc.add(
                                const SubmitPointsToCashRateUpdateRequested(),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        foregroundColor: AppColors.pureWhite,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        disabledForegroundColor: AppColors.pureWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                      label: Text(
                        isUpdating ? 'Saving Rate...' : 'Save Conversion Rate',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
