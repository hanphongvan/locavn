import 'portal_loai.dart';

/// Role checks for UI and routing (authoritative: session / persisted `Loai`).
abstract final class RoleService {
  RoleService._();

  static bool isAdminUser(int? loai) => loai == PortalLoai.admin;

  static bool isTraderUser(int? loai) => loai == PortalLoai.trader;

  static bool isStoreUser(int? loai) => loai == PortalLoai.store;

  static bool isCitizenUser(int? loai) => loai == PortalLoai.citizen;

  static bool isLeaderUser(int? loai) => loai == PortalLoai.leader;
}
