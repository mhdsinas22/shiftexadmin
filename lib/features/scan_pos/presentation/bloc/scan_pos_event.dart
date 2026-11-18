import 'package:shiftexadmin/features/scan_pos/domain/entities/verified_pos_customer_entity.dart';
import 'package:shiftexadmin/features/settings/points_to_cash/domain/entities/points_to_cash_config_entity.dart';

abstract class ScanPosEvent {
  const ScanPosEvent();
}

class InitializeScanPosRequested extends ScanPosEvent {
  const InitializeScanPosRequested();
}

class RefreshPosRateConfigRequested extends ScanPosEvent {
  const RefreshPosRateConfigRequested();
}

class RefreshSelectedCustomerWalletRequested extends ScanPosEvent {
  const RefreshSelectedCustomerWalletRequested();
}

class RefreshClaimValidationRequested extends ScanPosEvent {
  const RefreshClaimValidationRequested();
}

class CentralRateConfigUpdatedEvent extends ScanPosEvent {
  final PointsToCashConfigEntity config;
  const CentralRateConfigUpdatedEvent(this.config);
}

class ScanPosModeChanged extends ScanPosEvent {
  final ScanPosMode mode;
  const ScanPosModeChanged(this.mode);
}

class QrCodeDetectedEvent extends ScanPosEvent {
  final String rawValue;
  const QrCodeDetectedEvent(this.rawValue);
}

class ManualQrSubmittedEvent extends ScanPosEvent {
  final String code;
  const ManualQrSubmittedEvent(this.code);
}

class SearchCustomersQueryChanged extends ScanPosEvent {
  final String query;
  const SearchCustomersQueryChanged(this.query);
}

class ManualCustomerSelectedEvent extends ScanPosEvent {
  final VerifiedPosCustomerEntity customer;
  const ManualCustomerSelectedEvent(this.customer);
}

class InstantPointsChanged extends ScanPosEvent {
  final String rawValue;
  const InstantPointsChanged(this.rawValue);
}

class FuturePointsChanged extends ScanPosEvent {
  final String rawValue;
  const FuturePointsChanged(this.rawValue);
}

class RedeemPointsChanged extends ScanPosEvent {
  final String rawValue;
  const RedeemPointsChanged(this.rawValue);
}

class BillNumberChanged extends ScanPosEvent {
  final String billNumber;
  const BillNumberChanged(this.billNumber);
}

class BranchNameChanged extends ScanPosEvent {
  final String branchName;
  const BranchNameChanged(this.branchName);
}

class ConfirmAllocatePointsRequested extends ScanPosEvent {
  const ConfirmAllocatePointsRequested();
}

class ConfirmRedeemClaimRequested extends ScanPosEvent {
  const ConfirmRedeemClaimRequested();
}

class RejectOrFlagClaimQrRequested extends ScanPosEvent {
  final String action;
  final String reason;

  const RejectOrFlagClaimQrRequested({
    required this.action,
    required this.reason,
  });
}

class ClaimTokenExpiredEvent extends ScanPosEvent {
  const ClaimTokenExpiredEvent();
}

class LoadRecentTransactionsRequested extends ScanPosEvent {
  final bool loadMore;
  const LoadRecentTransactionsRequested({this.loadMore = false});
}

class ClearSelectedCustomerRequested extends ScanPosEvent {
  const ClearSelectedCustomerRequested();
}
