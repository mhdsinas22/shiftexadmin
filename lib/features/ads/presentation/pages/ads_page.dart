import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftexadmin/core/constants/app_colors.dart';
import 'package:shiftexadmin/core/di/injection_container.dart';
import 'package:shiftexadmin/core/routes/route_names.dart';
import 'package:shiftexadmin/features/ads/presentation/bloc/advertisement_bloc.dart';
import 'package:shiftexadmin/features/ads/presentation/bloc/advertisement_event.dart';
import 'package:shiftexadmin/features/ads/presentation/bloc/advertisement_state.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_campaign_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_campaign_card_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_delete_dialog_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_edit_modal_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_live_preview_dialog_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_filter_chips_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_header_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_page_shimmer_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_statistics_grid_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/quick_create_popup_widget.dart';

class AdsPage extends StatelessWidget {
  const AdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdvertisementBloc>(
      create: (_) =>
          sl<AdvertisementBloc>()..add(const LoadAdvertisementsEvent()),
      child: const AdsPageView(),
    );
  }
}

class AdsPageView extends StatelessWidget {
  const AdsPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AdvertisementBloc, AdvertisementState>(
          listenWhen: (previous, current) {
            return previous.errorMessage != current.errorMessage ||
                previous.successMessage != current.successMessage;
          },
          listener: (context, state) {
            if (state.errorMessage.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: AppColors.purered,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state.successMessage != null &&
                state.successMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.eifGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<AdvertisementBloc>();
            final isInitialShimmer =
                !state.hasLoadedOnce &&
                (state.status == AdvertisementStatus.initial ||
                    state.status == AdvertisementStatus.loading);

            return RefreshIndicator(
              onRefresh: () async {
                bloc.add(const LoadAdvertisementsEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    AdsHeaderWidget(
                      onNewAdPressed: () {
                        bloc.add(const ToggleQuickCreateEvent());
                      },
                      onNotificationPressed: () {
                        bloc.add(const LoadAdvertisementsEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ad campaigns & metrics synced.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onProfilePressed: () {
                        final router = GoRouter.maybeOf(context);
                        if (router != null) {
                          router.go(RouteNames.settingsRoute);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    if (isInitialShimmer)
                      const AdsPageShimmerWidget()
                    else ...[
                      // Statistics Grid (2x2)
                      AdsStatisticsGridWidget(statistics: state.statistics),
                      const SizedBox(height: 16),

                      // Filter Chips (Horizontal)
                      AdsFilterChipsWidget(
                        selectedFilter: state.selectedFilter,
                        statistics: state.statistics,
                        onFilterChanged: (filter) {
                          bloc.add(FilterAdvertisementsEvent(filter));
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quick Create Popup (Collapsible)
                      QuickCreatePopupWidget(
                        isExpanded: state.isQuickCreateExpanded,
                        onToggleExpand: () {
                          bloc.add(const ToggleQuickCreateEvent());
                        },
                        onSubmit:
                            (
                              ad, {
                              isPublish = false,
                              isSchedule = false,
                              imageBytes,
                              imageFileName,
                            }) {
                              if (isPublish) {
                                bloc.add(
                                  CreateAdvertisementEvent(
                                    advertisement: ad.copyWith(
                                      status: 'published',
                                      publishedAt: DateTime.now(),
                                    ),
                                    imageBytes: imageBytes,
                                    imageFileName: imageFileName,
                                  ),
                                );
                              } else if (isSchedule) {
                                bloc.add(
                                  CreateAdvertisementEvent(
                                    advertisement: ad.copyWith(
                                      status: 'published',
                                    ),
                                    imageBytes: imageBytes,
                                    imageFileName: imageFileName,
                                  ),
                                );
                              } else {
                                bloc.add(
                                  CreateAdvertisementEvent(
                                    advertisement: ad.copyWith(status: 'draft'),
                                    imageBytes: imageBytes,
                                    imageFileName: imageFileName,
                                  ),
                                );
                              }
                            },
                      ),
                      const SizedBox(height: 22),

                      // Campaign Library Heading
                      const Text(
                        'Campaign Library',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campaign Cards
                      if (state.status == AdvertisementStatus.loading) ...[
                        const AdCampaignShimmerListWidget(itemCount: 3),
                      ] else if (state.advertisements.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.campaign_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No campaigns found',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'There are no campaigns matching "${state.selectedFilter}".',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ...state.advertisements.map((ad) {
                          return AdCampaignCardWidget(
                            advertisement: ad,
                            onPreview: () {
                              AdLivePreviewDialogWidget.show(
                                context,
                                advertisement: ad,
                                onTrackEvent: (id, type) {
                                  bloc.add(
                                    TrackAdvertisementEventOccurred(
                                      advertisementId: id,
                                      eventType: type,
                                    ),
                                  );
                                },
                              );
                            },
                            onEdit: () {
                              AdEditModalWidget.show(
                                context,
                                advertisement: ad,
                                onSave: (updated, {imageBytes, imageFileName}) {
                                  bloc.add(
                                    UpdateAdvertisementEvent(
                                      advertisement: updated,
                                      imageBytes: imageBytes,
                                      imageFileName: imageFileName,
                                    ),
                                  );
                                },
                              );
                            },
                            onDeactivate: () {
                              bloc.add(DeactivateAdvertisementEvent(ad.id));
                            },
                            onDelete: () {
                              AdDeleteDialogWidget.show(
                                context,
                                title: ad.title,
                                onConfirm: () {
                                  bloc.add(DeleteAdvertisementEvent(ad.id));
                                },
                              );
                            },
                            onCancelSchedule: () {
                              bloc.add(DeactivateAdvertisementEvent(ad.id));
                            },
                            onPublish: () {
                              bloc.add(PublishAdvertisementEvent(ad.id));
                            },
                          );
                        }),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
