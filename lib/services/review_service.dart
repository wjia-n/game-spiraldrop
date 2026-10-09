import 'package:in_app_review/in_app_review.dart';

/// Play review prompt. Completely graceful: on any store/sideload state it
/// silently does nothing — never crashes, never blocks.
class ReviewService {
  final InAppReview _review = InAppReview.instance;
  bool _asked = false;

  /// Ask at most [maxTimes] per install, only when the app can show it.
  Future<void> maybeAsk({int maxTimes = 3, required int alreadyAsked}) async {
    if (_asked || alreadyAsked >= maxTimes) return;
    _asked = true;
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      }
    } catch (_) {}
  }
}
