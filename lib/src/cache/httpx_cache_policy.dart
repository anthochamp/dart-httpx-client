enum HttpxCachePolicy {
  /// Standard behaviour.
  standard,

  /// Behaves as if there is no HTTP cache. It will still update the cache
  /// with the response.
  straightToNetwork,

  /// Uses any response in the HTTP cache matching the request, not paying
  /// attention to Pragma / Cache Control directives in both the request and
  /// the cached response(s).
  ignoreDirectives,

  /// Enable stale-while-revalidate even for cached responses which do not have
  /// the directive (or if it's past its lifetime). It does not bypass Pragma /
  /// Cache Control directives (no-cache and/or min-fresh directives may prevent
  /// revalidation in background).
  staleWhileRevalidate,
}
