import 'package:anthochamp_dart_essentials/dart_essentials.dart';
import 'package:httpx_client/src/cache/httpx_cache_utilities.dart';
import 'package:httpx_client/src/cache/store/httpx_cache_store_entry.dart';
import 'package:httpx_client/src/headers/extensions/httpx_headers_cache_extension.dart';
import 'package:httpx_client/src/headers/httpx_headers.dart';

class HttpxCacheContext {
  final DateTime referenceTime;
  final Duration currentAge;
  final HttpxCacheControl? requestCacheControl;
  final HttpxCacheControl? responseCacheControl;
  final Duration? freshnessLifetime;
  final bool? isHeuristicFreshnessLifetime;
  final Duration? staleWhileRevalidateLifetime;
  final Duration? staleIfErrorLifetime;
  final Duration? freshnessTimeout;
  final Duration? staleWhileRevalidateTimeout;
  final Duration? staleIfErrorTimeout;
  final bool mustRevalidate;
  final bool isStale;
  final bool isStaleServeAllowed;
  final bool? isStaleWhileRevalidateAllowed;
  final bool? isStaleIfErrorAllowed;

  HttpxCacheContext._({
    required this.referenceTime,
    required this.currentAge,
    required this.requestCacheControl,
    required this.responseCacheControl,
    required this.freshnessLifetime,
    required this.isHeuristicFreshnessLifetime,
    required this.staleWhileRevalidateLifetime,
    required this.staleIfErrorLifetime,
    required this.freshnessTimeout,
    required this.staleWhileRevalidateTimeout,
    required this.staleIfErrorTimeout,
    required this.mustRevalidate,
    required this.isStale,
    required this.isStaleServeAllowed,
    required this.isStaleWhileRevalidateAllowed,
    required this.isStaleIfErrorAllowed,
  });

  factory HttpxCacheContext.from({
    required DateTime referenceTime,
    required HttpxHeaders requestHeaders,
    required HttpxCacheStoreEntry storeEntry,
    required Iterable<int> cacheableStatusCode,
  }) {
    final currentAge = HttpxCacheUtilities.computeCurrentAge(
      referenceTime: referenceTime,
      responseHeaders: storeEntry.responseHeaders,
      firstByteReceivedTime: storeEntry.firstByteReceivedTime,
      firstByteSentTime: storeEntry.firstByteSentTime,
    );

    var freshnessLifetime = HttpxCacheUtilities.computeFreshnessLifetime(
      responseHeaders: storeEntry.responseHeaders,
      firstByteReceivedTime: storeEntry.firstByteReceivedTime,
    );

    bool isHeuristicFreshnessLifetime;
    if (freshnessLifetime == null) {
      freshnessLifetime = HttpxCacheUtilities.computeHeuristicFreshnessLifetime(
        status: storeEntry.status,
        responseHeaders: storeEntry.responseHeaders,
        firstByteReceivedTime: storeEntry.firstByteReceivedTime,
        cacheableStatusCode: cacheableStatusCode,
      );

      isHeuristicFreshnessLifetime = freshnessLifetime != null;
    } else {
      isHeuristicFreshnessLifetime = false;
    }

    final requestCacheControl = requestHeaders.getCacheControl();
    final responseCacheControl = storeEntry.responseHeaders.getCacheControl();

    final staleWhileRevalidateLifetime =
        HttpxCacheUtilities.computeStaleWhileRevalidateLifetime(
      responseCacheControl: responseCacheControl,
    );
    final staleIfErrorLifetime =
        HttpxCacheUtilities.computeStaleIfErrorLifetime(
      requestCacheControl: requestCacheControl,
      responseCacheControl: responseCacheControl,
    );

    final staleWhileRevalidateTimeout = HttpxCacheUtilities.computeFreshness(
      freshnessLifetime: staleWhileRevalidateLifetime,
      currentAge: currentAge,
    );

    final staleIfErrorTimeout = HttpxCacheUtilities.computeFreshness(
      freshnessLifetime: staleIfErrorLifetime,
      currentAge: currentAge,
    );

    final freshnessTimeout = HttpxCacheUtilities.computeFreshness(
      freshnessLifetime: freshnessLifetime,
      currentAge: currentAge,
    );

    final isStale = HttpxCacheUtilities.computeIsStale(
      currentAge: currentAge,
      freshness: freshnessTimeout,
      requestCacheControl: requestCacheControl,
      responseCacheControl: responseCacheControl,
    );

    return HttpxCacheContext._(
      referenceTime: referenceTime,
      currentAge: currentAge,
      requestCacheControl: requestCacheControl,
      responseCacheControl: responseCacheControl,
      freshnessLifetime: freshnessLifetime,
      isHeuristicFreshnessLifetime: isHeuristicFreshnessLifetime,
      staleWhileRevalidateLifetime: staleWhileRevalidateLifetime,
      staleIfErrorLifetime: staleIfErrorLifetime,
      freshnessTimeout: freshnessTimeout,
      staleWhileRevalidateTimeout: staleWhileRevalidateTimeout,
      staleIfErrorTimeout: staleIfErrorTimeout,
      mustRevalidate: HttpxCacheUtilities.computeMustRevalidate(
        requestPragmaNoCache: requestHeaders.hasPragmaNoCache(),
        requestCacheControl: requestCacheControl,
        responseCacheControl: responseCacheControl,
        freshness: freshnessTimeout,
        isStale: isStale,
      ),
      isStale: isStale,
      isStaleServeAllowed: HttpxCacheUtilities.computeStaleServeAllowed(
        requestCacheControl: requestCacheControl,
        freshness: freshnessTimeout,
      ),
      isStaleWhileRevalidateAllowed:
          DurationUtil.gt(staleWhileRevalidateTimeout, Duration.zero),
      isStaleIfErrorAllowed:
          DurationUtil.gt(staleIfErrorTimeout, Duration.zero),
    );
  }

  @override
  String toString() {
    return {
      'currentAge': currentAge,
      'responseCacheControl': responseCacheControl,
      'freshnessLifetime': freshnessLifetime,
      'isHeuristicFreshnessLifetime': isHeuristicFreshnessLifetime,
      'staleWhileRevalidateLifetime': staleWhileRevalidateLifetime,
      'staleIfErrorLifetime': staleIfErrorLifetime,
      'freshnessTimeout': freshnessTimeout,
      'staleWhileRevalidateTimeout': staleWhileRevalidateTimeout,
      'staleIfErrorTimeout': staleIfErrorTimeout,
      'mustRevalidate': mustRevalidate,
      'isStale': isStale,
      'isStaleServeAllowed': isStaleServeAllowed,
      'isStaleWhileRevalidateAllowed': isStaleWhileRevalidateAllowed,
      'isStaleIfErrorAllowed': isStaleIfErrorAllowed,
    }.inspect(InspectOptions(preferCompact: false));
  }
}
