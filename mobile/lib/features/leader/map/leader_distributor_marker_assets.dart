import 'package:flutter/material.dart';

import '../../../core/assets/map_marker_asset_paths.dart';
import '../presentation/leader_theme.dart';

/// Máy chủ: `0` an toàn, `1` cảnh báo, `2` nguy cơ — đồng bộ API `trangThaiXang` / `trangThaiDau` / `fn_Leader_Map_DistributorReserveDisplayStatus`.
const int kLeaderDistributorDisplayStatusSafe = 0;

const int kLeaderDistributorDisplayStatusWarning = 1;

const int kLeaderDistributorDisplayStatusDanger = 2;

/// PNG marker theo **trạng thái do máy chủ gửi** (không suy từ ngày trên client).
String getDistributorMarkerAssetForDisplayStatus(int status) {
  return switch (status) {
    kLeaderDistributorDisplayStatusSafe => MapMarkerAssetPaths.distributorSafe,
    kLeaderDistributorDisplayStatusDanger => MapMarkerAssetPaths.distributorDanger,
    _ => MapMarkerAssetPaths.distributorWarning,
  };
}

/// Nhãn theo mã trạng thái máy chủ.
String getDistributorStatusLabelForDisplayStatus(int status) {
  return switch (status) {
    kLeaderDistributorDisplayStatusSafe => 'An toàn',
    kLeaderDistributorDisplayStatusDanger => 'Nguy cơ',
    _ => 'Cảnh báo',
  };
}

Color getDistributorStatusColorForDisplayStatus(int status) {
  return switch (status) {
    kLeaderDistributorDisplayStatusSafe => LeaderTheme.coverageOk,
    kLeaderDistributorDisplayStatusDanger => LeaderTheme.alert,
    _ => LeaderTheme.coverageWarn,
  };
}
