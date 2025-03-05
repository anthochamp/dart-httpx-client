// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';

import 'package:ac_dart_essentials/ac_dart_essentials.dart';
import 'package:collection/collection.dart';

import '../headers/extensions/httpx_headers_cache_extension.dart';
import '../headers/extensions/httpx_headers_typed_extension.dart';
import '../headers/httpx_headers.dart';
import '../httpx_request.dart';
import '../httpx_response.dart';
import '../httpx_typedefs.dart';
import 'httpx_cache.dart';
import 'httpx_cache_context.dart';
import 'httpx_cache_policy.dart';
import 'httpx_cache_response.dart';
import 'httpx_cache_utilities.dart';
import 'store/httpx_cache_combined_store.dart';
import 'store/httpx_cache_store.dart';
import 'store/httpx_cache_store_entry.dart';

// https://datatracker.ietf.org/doc/html/rfc7231#section-6.1
const kInitialCacheableStatusCode = [
  200,
  203,
  204,
  /*206, partial content is not supported */
  300,
  301,
  404,
  405,
  410,
  414,
  501,
];

// https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.3
const kInitialCacheableHttpMethods = [
  'HEAD',
  'GET',
  /*'POST', TBD */
];

class _ConditionalRequestResult {
  final HttpxResponse response;
  final bool cacheableResponse;
  final bool forwardResponse;

  _ConditionalRequestResult({
    required this.response,
    required this.cacheableResponse,
    required this.forwardResponse,
  });
}

class _ForwardResponseResult {
  final HttpxResponse? forwardResponse;

  _ForwardResponseResult({this.forwardResponse});
}

class _DisambiguateResult extends _ForwardResponseResult {
  final HttpxCacheStoreEntry? storeEntry;

  _DisambiguateResult({super.forwardResponse, this.storeEntry});
}

class _RevalidateResult extends _ForwardResponseResult {
  final HttpxResponse? response;
  final bool validationFailed;
  final bool entryInvalidated;

  _RevalidateResult({
    super.forwardResponse,
    this.response,
    required this.validationFailed,
    required this.entryInvalidated,
  });
}

class HttpxCacheImpl implements HttpxCache {
  final HttpxCreateNetworkRequestCallback createNetworkRequestCallback;

  HttpxCacheImpl({
    required this.createNetworkRequestCallback,
    this.cacheableStatusCode = kInitialCacheableStatusCode,
    this.cacheableHttpMethods = kInitialCacheableHttpMethods,
  });

  final _store = HttpxCacheStoreCombined();

  HttpxLogCallback? logCallback;

  @override
  List<int> cacheableStatusCode;
  @override
  List<String> cacheableHttpMethods;

  @override
  List<HttpxCacheStore> get stores => _store.stores;

  @override
  Future<void> update({
    required String method,
    required Uri uri,
    required HttpxHeaders requestHeaders,
    required DateTime firstByteSentTime,
    required HttpxResponse response,
    required List<int> responseBody,
  }) async {
    if (!kSafeHttpMethods.contains(method)) {
      logCallback?.call(
        '[$method $uri CACHE] Invalidating uri (non-safe HTTP method).',
      );

      await _store.removeWhere(
        primaryKey: HttpxCacheStore.composePrimaryKey(uri),
      );
    }

    if (!HttpxCacheUtilities.isCacheable(
      method: method,
      requestHeaders: requestHeaders,
      response: response,
      cacheableHttpMethods: cacheableHttpMethods,
      cacheableStatusCode: cacheableStatusCode,
    )) {
      logCallback?.call(
        '[$method $uri CACHE] Stores update cancelled (non-cacheable)',
      );

      return;
    }

    logCallback?.call('[$method $uri CACHE] Update stores...');

    await _store.removeWhere(
      primaryKey: HttpxCacheStore.composePrimaryKey(uri),
      requestHeadersFilter:
          HttpxCacheUtilities.composeVaryingRequestHeadersEntries(
            requestHeaders: requestHeaders,
            responseHeaders: response.headers,
          ),
    );

    await _store.add(
      HttpxCacheStoreEntry.fromResponse(
        uri: uri,
        requestHeaders: requestHeaders,
        firstByteSentTime: firstByteSentTime,
        response: response,
        responseBody: responseBody,
      ),
    );

    logCallback?.call('[$method $uri CACHE] Stores updated.');
  }

  @override
  Future<HttpxResponse?> process({
    required HttpxRequest request,
    required HttpxCachePolicy cachePolicy,
    required Duration? timeout,
    required Duration? connectionTimeout,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();

    logCallback?.call(
      '[${request.method} ${request.uri} CACHE] Processing... ${{'cachePolicy': cachePolicy, 'timeout': timeout, 'connectionTimeout': connectionTimeout}.inspect()}',
    );

    if (cachePolicy == HttpxCachePolicy.straightToNetwork) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] straightToNetwork cache policy, aborting with no response.',
      );

      return null;
    }

    final requestCacheControl = request.headers.getCacheControl();

    final hasCacheControlOnlyIfCached =
        requestCacheControl?.onlyIfCached == true;

    final voidResponse =
        hasCacheControlOnlyIfCached
            ? HttpxCacheResponse.gatewayTimeout()
            : null;
    final voidResponseText =
        hasCacheControlOnlyIfCached ? 'gateway timeout' : 'no response';

    if (requestCacheControl?.noStore == true) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] Cache-Control: no-store in request, aborting with $voidResponseText',
      );

      return voidResponse;
    }

    final disambiguateResult = await _disambiguate(
      request: request,
      timeout: stopWatch.timeLeft(timeout),
      connectionTimeout: connectionTimeout,
      storeEntries: await _store.getAll(
        HttpxCacheStore.composePrimaryKey(request.uri),
      ),
    );

    if (disambiguateResult.forwardResponse != null) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] Forwarding disambiguate response',
      );

      return disambiguateResult.forwardResponse;
    }

    if (disambiguateResult.storeEntry == null) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] No entry found (or disambiguate failed), aborting with $voidResponseText',
      );

      return voidResponse;
    }

    final storeEntry = disambiguateResult.storeEntry!;

    bool? validationFailed;

    HttpxCacheContext context = HttpxCacheContext.from(
      referenceTime: DateTime.now(),
      requestHeaders: request.headers,
      storeEntry: storeEntry,
      cacheableStatusCode: cacheableStatusCode,
    );

    logCallback?.call(
      '[${request.method} ${request.uri} CACHE] Matched a single cached entry: $context',
    );

    final shouldRevalidate =
        context.mustRevalidate ||
        (context.isStale && !context.isStaleServeAllowed);

    if (shouldRevalidate && cachePolicy != HttpxCachePolicy.ignoreDirectives) {
      final revalidateResultFuture = _revalidate(
        request: request,
        timeout: stopWatch.timeLeft(timeout),
        connectionTimeout: connectionTimeout,
        storeEntry: storeEntry,
      );

      final staleWhileRevalidate =
          cachePolicy == HttpxCachePolicy.staleWhileRevalidate ||
          context.isStaleWhileRevalidateAllowed == true;

      // https://datatracker.ietf.org/doc/html/rfc5861#section-3
      if (staleWhileRevalidate && !context.mustRevalidate) {
        logCallback?.call(
          '[${request.method} ${request.uri} CACHE] Serving stale while revalidating in background...',
        );

        unawaited(
          revalidateResultFuture.then((revalidateResult) async {
            logCallback?.call(
              '[${request.method} ${request.uri} CACHE] Background revalidation completed ${{'validationFailed': revalidateResult.validationFailed, 'forwardResponse': revalidateResult.forwardResponse != null}}.toLogString()',
            );

            if (revalidateResult.forwardResponse != null) {
              final responseBody = await revalidateResult.forwardResponse!.fold(
                <int>[],
                (previous, element) => previous..addAll(element),
              );

              await update(
                method: request.method,
                uri: request.uri,
                requestHeaders: request.headers,
                firstByteSentTime: request.firstByteSentTime!,
                response: revalidateResult.forwardResponse!,
                responseBody: responseBody,
              );
            }
          }),
        );
      } else {
        final revalidateResult = await revalidateResultFuture;

        validationFailed = revalidateResult.validationFailed;

        if (validationFailed) {
          if (context.mustRevalidate) {
            logCallback?.call(
              '[${request.method} ${request.uri} CACHE] Mandatory validation failed, aborting with ${revalidateResult.forwardResponse == null ? voidResponseText : 'forwarding validation response'}',
            );

            return revalidateResult.forwardResponse ?? voidResponse;
          } else {
            // https://datatracker.ietf.org/doc/html/rfc5861#section-4
            final staleIfError =
                context.isStaleIfErrorAllowed == true &&
                kStaleIfErrorStatusCodes.contains(
                  revalidateResult.response?.status ?? 0,
                );

            if (!staleIfError) {
              logCallback?.call(
                '[${request.method} ${request.uri} CACHE] Validation failed and staleIfError not applicable, aborting with ${revalidateResult.forwardResponse == null ? voidResponseText : 'forwarding validation response'}',
              );

              return revalidateResult.forwardResponse ?? voidResponse;
            }
          }
        } else if (revalidateResult.entryInvalidated) {
          logCallback?.call(
            '[${request.method} ${request.uri} CACHE] Validation successful but entry has been invalidated, aborting with ${revalidateResult.forwardResponse == null ? voidResponseText : 'forwarding validation response'}',
          );

          return revalidateResult.forwardResponse ?? voidResponse;
        }

        if (revalidateResult.forwardResponse != null) {
          logCallback?.call(
            '[${request.method} ${request.uri} CACHE] Forwarding validation response',
          );

          return revalidateResult.forwardResponse;
        }
      }
    }

    final cacheResponse = HttpxCacheResponse.from(
      storeEntry: storeEntry,
      context: context,
      validationFailed: validationFailed,
    );

    logCallback?.call(
      '[${request.method} ${request.uri} CACHE] Returning cached response: ${{'firstByteReceivedTime': cacheResponse.firstByteReceivedTime, 'redirects': cacheResponse.redirects, 'status': cacheResponse.status, 'statusText': cacheResponse.statusText, 'headers': cacheResponse.headers}.inspect()}',
    );

    return cacheResponse;
  }

  Future<_ConditionalRequestResult?> _conditionalRequest({
    required HttpxRequest request,
    required Iterable<String> ifNoneMatch,
    required DateTime? ifModifiedSince,
    required Duration? timeout,
    required Duration? connectionTimeout,
  }) async {
    String conditionalMethod;
    if (ifModifiedSince == null && ifNoneMatch.isEmpty) {
      conditionalMethod = 'HEAD';
    } else {
      conditionalMethod = request.method;
    }

    logCallback?.call(
      '[${request.method} ${request.uri} CACHE] Conditional request... ${{'ifNoneMatch': ifNoneMatch, 'ifModifiedSince': ifModifiedSince, 'method': conditionalMethod}.inspect()}',
    );

    final stopWatch = Stopwatch();
    stopWatch.start();

    final conditionalHeaders = request.headers.clone();

    // https://datatracker.ietf.org/doc/html/rfc7234#section-4.3.1
    conditionalHeaders[HttpHeaders.ifNoneMatchHeader] = ifNoneMatch;

    // https://datatracker.ietf.org/doc/html/rfc7232#section-2.3
    // NB. Will be ignored by server if the if-none-match header is set.
    conditionalHeaders.setDateTimeField(
      HttpHeaders.ifModifiedSinceHeader,
      ifModifiedSince,
    );

    HttpxResponse conditionalResponse;

    try {
      final conditionalRequest = await createNetworkRequestCallback(
        method: conditionalMethod,
        uri: request.uri,
        headers: conditionalHeaders,
        maxRedirects: request.maxRedirects,
        connectionTimeout: stopWatch.timeLeft(timeout, connectionTimeout),
      );

      conditionalResponse = await conditionalRequest.close(
        stopWatch.timeLeft(timeout),
      );
    } catch (error) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] Conditional request failed: $error',
      );

      return null;
    }

    if (conditionalMethod != request.method &&
        conditionalResponse.status == HttpStatus.methodNotAllowed) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] Tried conditional request with $conditionalMethod method instead of ${request.method} but the it ain\'t allowed by the server',
      );

      return null;
    }

    return _ConditionalRequestResult(
      response: conditionalResponse,
      cacheableResponse: cacheableStatusCode.contains(
        conditionalResponse.status,
      ),
      forwardResponse: conditionalMethod == request.method,
    );
  }

  Future<_DisambiguateResult> _disambiguate({
    required HttpxRequest request,
    required Duration? timeout,
    required Duration? connectionTimeout,
    required Iterable<HttpxCacheStoreEntry> storeEntries,
  }) async {
    Iterable<HttpxCacheStoreEntry> preferredStoreEntries;

    if (storeEntries.length > 1) {
      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] Disambiguating ${storeEntries.length} entries...',
      );

      preferredStoreEntries = HttpxCacheUtilities.selectPreferredStoreEntries(
        requestHeaders: request.headers,
        entries: storeEntries,
      );

      logCallback?.call(
        '[${request.method} ${request.uri} CACHE] ${preferredStoreEntries.length} entries left after content negociation',
      );
    } else {
      preferredStoreEntries = storeEntries;
    }

    if (preferredStoreEntries.isEmpty) {
      return _DisambiguateResult();
    } else if (preferredStoreEntries.length == 1) {
      return _DisambiguateResult(storeEntry: preferredStoreEntries.first);
    }

    final ifNoneMatch = preferredStoreEntries.expand<String>((e) {
      final etag = e.responseHeaders.getEtag();

      return etag == null ? [] : [etag];
    });

    // https://datatracker.ietf.org/doc/html/rfc7232#section-2.3
    // They (should) all have the same lastModified header so we take the first entry as reference.
    final ifModifiedSince =
        preferredStoreEntries
            .firstWhereOrNull(
              (e) => e.responseHeaders.getLastModified() != null,
            )
            ?.responseHeaders
            .getLastModified();

    final conditionalRequestResult = await _conditionalRequest(
      request: request,
      ifNoneMatch: ifNoneMatch,
      ifModifiedSince: ifModifiedSince,
      timeout: timeout,
      connectionTimeout: connectionTimeout,
    );

    HttpxCacheStoreEntry? matchingStoreEntry;

    if (conditionalRequestResult?.cacheableResponse == true) {
      final responseEtag = conditionalRequestResult!.response.headers.getEtag();

      for (final storeEntry in preferredStoreEntries) {
        if (responseEtag != null &&
            storeEntry.responseHeaders.getEtag() == responseEtag) {
          matchingStoreEntry = storeEntry;
        } else {
          await _store.removeWhere(
            primaryKey: HttpxCacheStore.composePrimaryKey(request.uri),
            responseHeadersFilter: storeEntry.responseHeaders.getEntries(),
          );
        }
      }
    }

    return _DisambiguateResult(
      storeEntry: matchingStoreEntry,
      forwardResponse:
          conditionalRequestResult?.forwardResponse == true
              ? conditionalRequestResult?.response
              : null,
    );
  }

  Future<_RevalidateResult> _revalidate({
    required HttpxRequest request,
    required Duration? timeout,
    required Duration? connectionTimeout,
    required HttpxCacheStoreEntry storeEntry,
  }) async {
    final etag = storeEntry.responseHeaders.getEtag();
    final ifModifiedSince = storeEntry.responseHeaders.getLastModified();

    final conditionalRequestResult = await _conditionalRequest(
      request: request,
      ifNoneMatch: etag == null ? [] : [etag],
      ifModifiedSince: ifModifiedSince,
      timeout: timeout,
      connectionTimeout: connectionTimeout,
    );

    final conditionalRequestResponse = conditionalRequestResult?.response;

    final bool notModified;

    // https://datatracker.ietf.org/doc/html/rfc7232#section-6
    if (ifModifiedSince != null ||
        (request.method == 'GET' || request.method == 'HEAD')) {
      notModified =
          conditionalRequestResponse?.status == HttpStatus.notModified;
    } else {
      notModified =
          conditionalRequestResponse?.status == HttpStatus.preconditionFailed;
    }

    final entryMatch =
        notModified ||
        (conditionalRequestResponse?.headers.getEtag() == etag &&
            conditionalRequestResponse?.status == storeEntry.status);

    logCallback?.call(
      '[${request.method} ${request.uri} CACHE] Validation done: ${{'entryMatch': entryMatch, 'notModified': notModified}.inspect()}',
    );

    if (!entryMatch) {
      await _store.removeWhere(
        primaryKey: HttpxCacheStore.composePrimaryKey(request.uri),
        responseHeadersFilter: storeEntry.responseHeaders.getEntries(),
      );
    }

    return _RevalidateResult(
      response: conditionalRequestResponse,
      forwardResponse:
          conditionalRequestResult?.forwardResponse == true && !notModified
              ? conditionalRequestResponse
              : null,
      validationFailed:
          conditionalRequestResult?.cacheableResponse != true && !notModified,
      entryInvalidated: !entryMatch,
    );
  }
}
