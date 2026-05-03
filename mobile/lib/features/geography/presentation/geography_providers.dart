import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geography_api.dart';
import '../data/models/district_response.dart';
import '../data/models/province_response.dart';

/// `GET /api/geography/provinces`
final geographyProvincesProvider =
    FutureProvider.autoDispose<List<ProvinceResponse>>((ref) async {
  final api = ref.watch(geographyApiProvider);
  return api.getProvinces();
});

/// `GET /api/geography/districts?provinceCode=`
final geographyDistrictsProvider =
    FutureProvider.autoDispose.family<List<DistrictResponse>, String>((ref, provinceCode) async {
  final trimmed = provinceCode.trim();
  if (trimmed.isEmpty) return [];
  final api = ref.watch(geographyApiProvider);
  return api.getDistricts(trimmed);
});
