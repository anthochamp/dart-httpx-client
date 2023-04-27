import 'package:test/test.dart';

import 'package:ac_httpx_client/ac_httpx_client.dart';

void main() {
  group('CacheControl', () {
    test('', () {
      final headers = HttpxHeaders.fromMap({
        'cache-control': 'max-age=604800, must-revalidate',
      });

      final cacheControl = headers.getCacheControl();
      expect(cacheControl, isNotNull);

      expect(
        cacheControl!.mustRevalidate,
        equals(true),
      );

      expect(
        cacheControl.maxAgeValue,
        equals(const Duration(seconds: 604800)),
      );
    });

    test('', () {
      final headers = HttpxHeaders.fromMap({
        'cache-control':
            'no-cache, private="header1, header2, header3, no-transform", no-store',
      });

      final cacheControl = headers.getCacheControl();
      expect(cacheControl, isNotNull);

      expect(cacheControl!.noCache, equals(true));
      expect(cacheControl.noCacheValues, equals([]));
      expect(cacheControl.noStore, equals(true));
      expect(cacheControl.noTransform, equals(false));

      expect(cacheControl.private, equals(true));
      expect(
        cacheControl.privateValues,
        equals(['header1', 'header2', 'header3', 'no-transform']),
      );
    });
  });
}
