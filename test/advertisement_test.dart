import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/features/ads/data/models/advertisement_model.dart';
import 'package:shiftexadmin/features/ads/data/models/advertisement_statistics_model.dart';
import 'package:shiftexadmin/features/ads/domain/entities/advertisement_entity.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ad_campaign_card_shimmer_widget.dart';
import 'package:shiftexadmin/features/ads/presentation/widgets/ads_page_shimmer_widget.dart';

void main() {
  group('AdvertisementEntity & Model tests', () {
    test('effectiveStatus calculates correctly for active, scheduled, and draft', () {
      final now = DateTime.now();

      final activeAd = AdvertisementEntity(
        id: '1',
        title: 'Active Promo',
        offerDetails: 'Active Details',
        startAt: now.subtract(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 3)),
        status: 'published',
        createdAt: now,
        updatedAt: now,
      );
      expect(activeAd.isActive, isTrue);
      expect(activeAd.isScheduled, isFalse);
      expect(activeAd.isDraft, isFalse);
      expect(activeAd.effectiveStatus, 'active');

      final scheduledAd = AdvertisementEntity(
        id: '2',
        title: 'Scheduled Promo',
        offerDetails: 'Scheduled Details',
        startAt: now.add(const Duration(days: 2)),
        endAt: now.add(const Duration(days: 5)),
        status: 'published',
        createdAt: now,
        updatedAt: now,
      );
      expect(scheduledAd.isScheduled, isTrue);
      expect(scheduledAd.isActive, isFalse);
      expect(scheduledAd.effectiveStatus, 'scheduled');

      final draftAd = AdvertisementEntity(
        id: '3',
        title: 'Draft Promo',
        offerDetails: 'Draft Details',
        startAt: now,
        endAt: now.add(const Duration(days: 1)),
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      );
      expect(draftAd.isDraft, isTrue);
      expect(draftAd.effectiveStatus, 'draft');

      final deactivatedAd = AdvertisementEntity(
        id: '4',
        title: 'Deactivated Promo',
        offerDetails: 'Deactivated Details',
        startAt: now.subtract(const Duration(days: 5)),
        endAt: now.add(const Duration(days: 5)),
        status: 'deactivated',
        createdAt: now,
        updatedAt: now,
      );
      expect(deactivatedAd.isDeactivated, isTrue);
      expect(deactivatedAd.effectiveStatus, 'deactivated');

      final withDeactivatedTimestamp = deactivatedAd.copyWith(
        deactivatedAt: now,
      );
      final reactivatedAd = withDeactivatedTimestamp.copyWith(
        status: 'published',
        publishedAt: now,
        clearDeactivatedAt: true,
      );
      expect(reactivatedAd.deactivatedAt, isNull);
      expect(reactivatedAd.isDeactivated, isFalse);
      expect(reactivatedAd.isActive, isTrue);
      expect(reactivatedAd.effectiveStatus, 'active');
    });

    test('AdvertisementModel correctly serializes and deserializes', () {
      final now = DateTime.utc(2026, 11, 16, 12, 0, 0);
      final json = {
        'id': 'test-uuid-1234',
        'title': 'Diwali Super Points',
        'offer_details': '2X bonus points on all transactions',
        'image_url': 'https://example.com/banner.jpg',
        'popup_duration_seconds': 8,
        'frequency_type': 'once_per_day',
        'frequency_limit': 1,
        'start_at': now.toIso8601String(),
        'end_at': now.add(const Duration(days: 7)).toIso8601String(),
        'status': 'published',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'views_count': 1000,
        'claims_count': 350,
      };

      final model = AdvertisementModel.fromJson(json);
      expect(model.id, 'test-uuid-1234');
      expect(model.title, 'Diwali Super Points');
      expect(model.popupDurationSeconds, 8);
      expect(model.frequencyType, 'once_per_day');
      expect(model.viewsCount, 1000);
      expect(model.claimsCount, 350);
      expect(model.ctrPercent, 35.0);

      final outJson = model.toJson();
      expect(outJson['title'], 'Diwali Super Points');
      expect(outJson['popup_duration_seconds'], 8);
      expect(outJson['frequency_type'], 'once_per_day');
      expect(outJson['status'], 'published');
    });

    test('AdvertisementStatisticsModel calculates aggregates from list', () {
      final now = DateTime.now();

      final ads = [
        AdvertisementEntity(
          id: '1',
          title: 'Active 1',
          offerDetails: 'Details',
          startAt: now.subtract(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 1)),
          status: 'published',
          createdAt: now,
          updatedAt: now,
        ),
        AdvertisementEntity(
          id: '2',
          title: 'Scheduled 1',
          offerDetails: 'Details',
          startAt: now.add(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 5)),
          status: 'published',
          createdAt: now,
          updatedAt: now,
        ),
        AdvertisementEntity(
          id: '3',
          title: 'Draft 1',
          offerDetails: 'Details',
          startAt: now,
          endAt: now.add(const Duration(days: 1)),
          status: 'draft',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = AdvertisementStatisticsModel.fromList(ads);
      expect(stats.totalAds, 3);
      expect(stats.activeCount, 1);
      expect(stats.scheduledCount, 1);
      expect(stats.draftCount, 1);
      expect(stats.endedAndDraftCount, 1);
    });

    testWidgets('AdsPageShimmerWidget and AdCampaignShimmerListWidget render cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: AdsPageShimmerWidget(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AdsPageShimmerWidget), findsOneWidget);
      expect(find.byType(AdCampaignCardShimmerWidget), findsNWidgets(3));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdCampaignShimmerListWidget(itemCount: 2),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AdCampaignCardShimmerWidget), findsNWidgets(2));
    });
  });
}
