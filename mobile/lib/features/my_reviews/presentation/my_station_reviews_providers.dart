import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/my_station_reviews_models.dart';
import '../data/my_station_reviews_api.dart';

final myStationReviewsFirstPageProvider =
    FutureProvider.autoDispose<MyStationReviewsPage>((ref) async {
  final api = ref.watch(myStationReviewsApiProvider);
  return api.list(skip: 0, take: 50);
});
