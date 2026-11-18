import 'package:flutter/material.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/features/user_management/domain/entities/customer_entity.dart';

class TopEarnersCardWidget extends StatefulWidget {
  final List<CustomerEntity> customers;
  final String selectedRange;
  final bool isLoading;
  final ValueChanged<String>? onRangeChanged;
  final ValueChanged<CustomerEntity>? onCustomerTapped;

  const TopEarnersCardWidget({
    super.key,
    required this.customers,
    this.selectedRange = 'Weekly',
    this.isLoading = false,
    this.onRangeChanged,
    this.onCustomerTapped,
  });

  @override
  TopEarnersCardWidgetState createState() => TopEarnersCardWidgetState();
}

class TopEarnersCardWidgetState extends State<TopEarnersCardWidget> {
  late String _activeRange;

  @override
  void initState() {
    super.initState();
    _activeRange = widget.selectedRange;
  }

  @override
  void didUpdateWidget(covariant TopEarnersCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRange != oldWidget.selectedRange) {
      _activeRange = widget.selectedRange;
    }
  }

  List<CustomerEntity> _resolveTopEarners() {
    final eligible =
        widget.customers.where((c) => c.displayTopEarnerPoints > 0).toList()
          ..sort(
            (a, b) =>
                b.displayTopEarnerPoints.compareTo(a.displayTopEarnerPoints),
          );
    return eligible.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topList = _resolveTopEarners();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        size: 18,
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Top Earners',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRangeItem('Weekly'),
                    _buildRangeItem('Monthly'),
                    _buildRangeItem('All'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.linkBlue,
                  ),
                ),
              ),
            )
          else if (topList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No earnings records available for $_activeRange',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            )
          else
            ...List.generate(topList.length, (index) {
              final customer = topList[index];
              return _buildEarnerRow(rank: index + 1, customer: customer);
            }),
        ],
      ),
    );
  }

  Widget _buildRangeItem(String range) {
    final isSelected = _activeRange.toLowerCase() == range.toLowerCase();
    return GestureDetector(
      key: Key('top_earners_range_${range.toLowerCase()}'),
      onTap: () {
        setState(() {
          _activeRange = range;
        });
        widget.onRangeChanged?.call(range);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          range,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.pureWhite : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEarnerRow({
    required int rank,
    required CustomerEntity customer,
  }) {
    Color rankBg;
    Color rankText;
    if (rank == 1) {
      rankBg = const Color(0xFFFEF3C7);
      rankText = const Color(0xFFB45309);
    } else if (rank == 2) {
      rankBg = const Color(0xFFF1F5F9);
      rankText = const Color(0xFF475569);
    } else {
      rankBg = const Color(0xFFFFEDD5);
      rankText = const Color(0xFFC2410C);
    }

    final points = customer.displayTopEarnerPoints;
    final rupees = customer.displayTopEarnerRupees;
    final subtitleText = customer.earnedTxCount > 0
        ? '${customer.formattedCustomerId} • ${customer.earnedTxCount} ${customer.earnedTxCount == 1 ? 'reward' : 'rewards'}'
        : '${customer.formattedCustomerId} • Active member';

    return GestureDetector(
      onTap: () {
        if (widget.onCustomerTapped != null) {
          widget.onCustomerTapped!(customer);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rankText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFBAE6FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  customer.initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Customer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Dynamic Points & INR info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$points pts',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹${rupees.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.linkBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
