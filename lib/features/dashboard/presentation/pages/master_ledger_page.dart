import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/features/dashboard/domain/entities/master_ledger_entry_entity.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:shiftexadmin/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:shiftexadmin/features/dashboard/presentation/widgets/master_ledger_tile_widget.dart';

class MasterLedgerPage extends StatelessWidget {
  final LedgerCategoryFilter initialCategory;

  const MasterLedgerPage({
    super.key,
    this.initialCategory = LedgerCategoryFilter.all,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) =>
          getIt<DashboardBloc>()
            ..add(LoadFullMasterLedgerRequested(category: initialCategory)),
      child: const MasterLedgerView(),
    );
  }
}

class MasterLedgerView extends StatefulWidget {
  const MasterLedgerView({super.key});

  @override
  State<MasterLedgerView> createState() => _MasterLedgerViewState();
}

class _MasterLedgerViewState extends State<MasterLedgerView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router != null && router.canPop()) {
              router.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text(
          'Master Points Ledger',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final bloc = context.read<DashboardBloc>();

          return Column(
            children: [
              Container(
                color: AppColors.pureWhite,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('master_ledger_search_input'),
                      controller: _searchController,
                      onChanged: (value) {
                        bloc.add(
                          LoadFullMasterLedgerRequested(
                            category: state.selectedLedgerFilter,
                            searchQuery: value,
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by customer, TXN ID, bill # or branch...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 19,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: LedgerCategoryFilter.values.map((filter) {
                          final isSelected =
                              filter == state.selectedLedgerFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              key: Key(
                                'full_ledger_filter_tab_${filter.queryKey}',
                              ),
                              onTap: () => bloc.add(
                                LoadFullMasterLedgerRequested(
                                  category: filter,
                                  searchQuery: state.fullLedgerSearchQuery,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF090D16)
                                      : AppColors.pureWhite,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF090D16)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  filter.label,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.pureWhite
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.isFullLedgerLoading &&
                        state.fullLedgerEntries.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.linkBlue,
                        ),
                      )
                    : state.fullLedgerEntries.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching transactions found.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            state.fullLedgerEntries.length +
                            (state.hasMoreFullLedger ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= state.fullLedgerEntries.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: TextButton.icon(
                                  onPressed: state.isFullLedgerLoading
                                      ? null
                                      : () => bloc.add(
                                          const LoadFullMasterLedgerRequested(
                                            loadMore: true,
                                          ),
                                        ),
                                  icon: state.isFullLedgerLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.expand_more_rounded),
                                  label: const Text('Load Older Transactions'),
                                ),
                              ),
                            );
                          }
                          final entry = state.fullLedgerEntries[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: MasterLedgerTileWidget(entry: entry),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
