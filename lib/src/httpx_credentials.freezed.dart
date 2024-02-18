// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'httpx_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HttpxCredentials {
  String? get realm => throw _privateConstructorUsedError;
  bool get proxyCredentials => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String realm, String username, String password,
            bool proxyCredentials)
        basic,
    required TResult Function(
            String? realm, String accessToken, bool proxyCredentials)
        bearer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String realm, String username, String password,
            bool proxyCredentials)?
        basic,
    TResult? Function(String? realm, String accessToken, bool proxyCredentials)?
        bearer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String realm, String username, String password,
            bool proxyCredentials)?
        basic,
    TResult Function(String? realm, String accessToken, bool proxyCredentials)?
        bearer,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HttpxCredentialsBasic value) basic,
    required TResult Function(HttpxCredentialsBearer value) bearer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HttpxCredentialsBasic value)? basic,
    TResult? Function(HttpxCredentialsBearer value)? bearer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HttpxCredentialsBasic value)? basic,
    TResult Function(HttpxCredentialsBearer value)? bearer,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $HttpxCredentialsCopyWith<HttpxCredentials> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HttpxCredentialsCopyWith<$Res> {
  factory $HttpxCredentialsCopyWith(
          HttpxCredentials value, $Res Function(HttpxCredentials) then) =
      _$HttpxCredentialsCopyWithImpl<$Res, HttpxCredentials>;
  @useResult
  $Res call({String realm, bool proxyCredentials});
}

/// @nodoc
class _$HttpxCredentialsCopyWithImpl<$Res, $Val extends HttpxCredentials>
    implements $HttpxCredentialsCopyWith<$Res> {
  _$HttpxCredentialsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? realm = null,
    Object? proxyCredentials = null,
  }) {
    return _then(_value.copyWith(
      realm: null == realm
          ? _value.realm!
          : realm // ignore: cast_nullable_to_non_nullable
              as String,
      proxyCredentials: null == proxyCredentials
          ? _value.proxyCredentials
          : proxyCredentials // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HttpxCredentialsBasicImplCopyWith<$Res>
    implements $HttpxCredentialsCopyWith<$Res> {
  factory _$$HttpxCredentialsBasicImplCopyWith(
          _$HttpxCredentialsBasicImpl value,
          $Res Function(_$HttpxCredentialsBasicImpl) then) =
      __$$HttpxCredentialsBasicImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String realm, String username, String password, bool proxyCredentials});
}

/// @nodoc
class __$$HttpxCredentialsBasicImplCopyWithImpl<$Res>
    extends _$HttpxCredentialsCopyWithImpl<$Res, _$HttpxCredentialsBasicImpl>
    implements _$$HttpxCredentialsBasicImplCopyWith<$Res> {
  __$$HttpxCredentialsBasicImplCopyWithImpl(_$HttpxCredentialsBasicImpl _value,
      $Res Function(_$HttpxCredentialsBasicImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? realm = null,
    Object? username = null,
    Object? password = null,
    Object? proxyCredentials = null,
  }) {
    return _then(_$HttpxCredentialsBasicImpl(
      realm: null == realm
          ? _value.realm
          : realm // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      proxyCredentials: null == proxyCredentials
          ? _value.proxyCredentials
          : proxyCredentials // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$HttpxCredentialsBasicImpl implements HttpxCredentialsBasic {
  const _$HttpxCredentialsBasicImpl(
      {required this.realm,
      required this.username,
      required this.password,
      this.proxyCredentials = false});

  @override
  final String realm;
  @override
  final String username;
  @override
  final String password;
  @override
  @JsonKey()
  final bool proxyCredentials;

  @override
  String toString() {
    return 'HttpxCredentials.basic(realm: $realm, username: $username, password: $password, proxyCredentials: $proxyCredentials)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HttpxCredentialsBasicImpl &&
            (identical(other.realm, realm) || other.realm == realm) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.proxyCredentials, proxyCredentials) ||
                other.proxyCredentials == proxyCredentials));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, realm, username, password, proxyCredentials);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HttpxCredentialsBasicImplCopyWith<_$HttpxCredentialsBasicImpl>
      get copyWith => __$$HttpxCredentialsBasicImplCopyWithImpl<
          _$HttpxCredentialsBasicImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String realm, String username, String password,
            bool proxyCredentials)
        basic,
    required TResult Function(
            String? realm, String accessToken, bool proxyCredentials)
        bearer,
  }) {
    return basic(realm, username, password, proxyCredentials);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String realm, String username, String password,
            bool proxyCredentials)?
        basic,
    TResult? Function(String? realm, String accessToken, bool proxyCredentials)?
        bearer,
  }) {
    return basic?.call(realm, username, password, proxyCredentials);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String realm, String username, String password,
            bool proxyCredentials)?
        basic,
    TResult Function(String? realm, String accessToken, bool proxyCredentials)?
        bearer,
    required TResult orElse(),
  }) {
    if (basic != null) {
      return basic(realm, username, password, proxyCredentials);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HttpxCredentialsBasic value) basic,
    required TResult Function(HttpxCredentialsBearer value) bearer,
  }) {
    return basic(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HttpxCredentialsBasic value)? basic,
    TResult? Function(HttpxCredentialsBearer value)? bearer,
  }) {
    return basic?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HttpxCredentialsBasic value)? basic,
    TResult Function(HttpxCredentialsBearer value)? bearer,
    required TResult orElse(),
  }) {
    if (basic != null) {
      return basic(this);
    }
    return orElse();
  }
}

abstract class HttpxCredentialsBasic implements HttpxCredentials {
  const factory HttpxCredentialsBasic(
      {required final String realm,
      required final String username,
      required final String password,
      final bool proxyCredentials}) = _$HttpxCredentialsBasicImpl;

  @override
  String get realm;
  String get username;
  String get password;
  @override
  bool get proxyCredentials;
  @override
  @JsonKey(ignore: true)
  _$$HttpxCredentialsBasicImplCopyWith<_$HttpxCredentialsBasicImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HttpxCredentialsBearerImplCopyWith<$Res>
    implements $HttpxCredentialsCopyWith<$Res> {
  factory _$$HttpxCredentialsBearerImplCopyWith(
          _$HttpxCredentialsBearerImpl value,
          $Res Function(_$HttpxCredentialsBearerImpl) then) =
      __$$HttpxCredentialsBearerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? realm, String accessToken, bool proxyCredentials});
}

/// @nodoc
class __$$HttpxCredentialsBearerImplCopyWithImpl<$Res>
    extends _$HttpxCredentialsCopyWithImpl<$Res, _$HttpxCredentialsBearerImpl>
    implements _$$HttpxCredentialsBearerImplCopyWith<$Res> {
  __$$HttpxCredentialsBearerImplCopyWithImpl(
      _$HttpxCredentialsBearerImpl _value,
      $Res Function(_$HttpxCredentialsBearerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? realm = freezed,
    Object? accessToken = null,
    Object? proxyCredentials = null,
  }) {
    return _then(_$HttpxCredentialsBearerImpl(
      realm: freezed == realm
          ? _value.realm
          : realm // ignore: cast_nullable_to_non_nullable
              as String?,
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      proxyCredentials: null == proxyCredentials
          ? _value.proxyCredentials
          : proxyCredentials // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$HttpxCredentialsBearerImpl implements HttpxCredentialsBearer {
  const _$HttpxCredentialsBearerImpl(
      {this.realm, required this.accessToken, this.proxyCredentials = false});

  @override
  final String? realm;
  @override
  final String accessToken;
  @override
  @JsonKey()
  final bool proxyCredentials;

  @override
  String toString() {
    return 'HttpxCredentials.bearer(realm: $realm, accessToken: $accessToken, proxyCredentials: $proxyCredentials)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HttpxCredentialsBearerImpl &&
            (identical(other.realm, realm) || other.realm == realm) &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.proxyCredentials, proxyCredentials) ||
                other.proxyCredentials == proxyCredentials));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, realm, accessToken, proxyCredentials);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HttpxCredentialsBearerImplCopyWith<_$HttpxCredentialsBearerImpl>
      get copyWith => __$$HttpxCredentialsBearerImplCopyWithImpl<
          _$HttpxCredentialsBearerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String realm, String username, String password,
            bool proxyCredentials)
        basic,
    required TResult Function(
            String? realm, String accessToken, bool proxyCredentials)
        bearer,
  }) {
    return bearer(realm, accessToken, proxyCredentials);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String realm, String username, String password,
            bool proxyCredentials)?
        basic,
    TResult? Function(String? realm, String accessToken, bool proxyCredentials)?
        bearer,
  }) {
    return bearer?.call(realm, accessToken, proxyCredentials);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String realm, String username, String password,
            bool proxyCredentials)?
        basic,
    TResult Function(String? realm, String accessToken, bool proxyCredentials)?
        bearer,
    required TResult orElse(),
  }) {
    if (bearer != null) {
      return bearer(realm, accessToken, proxyCredentials);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HttpxCredentialsBasic value) basic,
    required TResult Function(HttpxCredentialsBearer value) bearer,
  }) {
    return bearer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HttpxCredentialsBasic value)? basic,
    TResult? Function(HttpxCredentialsBearer value)? bearer,
  }) {
    return bearer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HttpxCredentialsBasic value)? basic,
    TResult Function(HttpxCredentialsBearer value)? bearer,
    required TResult orElse(),
  }) {
    if (bearer != null) {
      return bearer(this);
    }
    return orElse();
  }
}

abstract class HttpxCredentialsBearer implements HttpxCredentials {
  const factory HttpxCredentialsBearer(
      {final String? realm,
      required final String accessToken,
      final bool proxyCredentials}) = _$HttpxCredentialsBearerImpl;

  @override
  String? get realm;
  String get accessToken;
  @override
  bool get proxyCredentials;
  @override
  @JsonKey(ignore: true)
  _$$HttpxCredentialsBearerImplCopyWith<_$HttpxCredentialsBearerImpl>
      get copyWith => throw _privateConstructorUsedError;
}
