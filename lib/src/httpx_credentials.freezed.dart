// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'httpx_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HttpxCredentials {

 String? get realm; bool get proxyCredentials;
/// Create a copy of HttpxCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpxCredentialsCopyWith<HttpxCredentials> get copyWith => _$HttpxCredentialsCopyWithImpl<HttpxCredentials>(this as HttpxCredentials, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpxCredentials&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.proxyCredentials, proxyCredentials) || other.proxyCredentials == proxyCredentials));
}


@override
int get hashCode => Object.hash(runtimeType,realm,proxyCredentials);

@override
String toString() {
  return 'HttpxCredentials(realm: $realm, proxyCredentials: $proxyCredentials)';
}


}

/// @nodoc
abstract mixin class $HttpxCredentialsCopyWith<$Res>  {
  factory $HttpxCredentialsCopyWith(HttpxCredentials value, $Res Function(HttpxCredentials) _then) = _$HttpxCredentialsCopyWithImpl;
@useResult
$Res call({
 String realm, bool proxyCredentials
});




}
/// @nodoc
class _$HttpxCredentialsCopyWithImpl<$Res>
    implements $HttpxCredentialsCopyWith<$Res> {
  _$HttpxCredentialsCopyWithImpl(this._self, this._then);

  final HttpxCredentials _self;
  final $Res Function(HttpxCredentials) _then;

/// Create a copy of HttpxCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? realm = null,Object? proxyCredentials = null,}) {
  return _then(_self.copyWith(
realm: null == realm ? _self.realm! : realm // ignore: cast_nullable_to_non_nullable
as String,proxyCredentials: null == proxyCredentials ? _self.proxyCredentials : proxyCredentials // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc


class HttpxCredentialsBasic implements HttpxCredentials {
  const HttpxCredentialsBasic({required this.realm, required this.username, required this.password, this.proxyCredentials = false});
  

@override final  String realm;
 final  String username;
 final  String password;
@override@JsonKey() final  bool proxyCredentials;

/// Create a copy of HttpxCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpxCredentialsBasicCopyWith<HttpxCredentialsBasic> get copyWith => _$HttpxCredentialsBasicCopyWithImpl<HttpxCredentialsBasic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpxCredentialsBasic&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.proxyCredentials, proxyCredentials) || other.proxyCredentials == proxyCredentials));
}


@override
int get hashCode => Object.hash(runtimeType,realm,username,password,proxyCredentials);

@override
String toString() {
  return 'HttpxCredentials.basic(realm: $realm, username: $username, password: $password, proxyCredentials: $proxyCredentials)';
}


}

/// @nodoc
abstract mixin class $HttpxCredentialsBasicCopyWith<$Res> implements $HttpxCredentialsCopyWith<$Res> {
  factory $HttpxCredentialsBasicCopyWith(HttpxCredentialsBasic value, $Res Function(HttpxCredentialsBasic) _then) = _$HttpxCredentialsBasicCopyWithImpl;
@override @useResult
$Res call({
 String realm, String username, String password, bool proxyCredentials
});




}
/// @nodoc
class _$HttpxCredentialsBasicCopyWithImpl<$Res>
    implements $HttpxCredentialsBasicCopyWith<$Res> {
  _$HttpxCredentialsBasicCopyWithImpl(this._self, this._then);

  final HttpxCredentialsBasic _self;
  final $Res Function(HttpxCredentialsBasic) _then;

/// Create a copy of HttpxCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? realm = null,Object? username = null,Object? password = null,Object? proxyCredentials = null,}) {
  return _then(HttpxCredentialsBasic(
realm: null == realm ? _self.realm : realm // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,proxyCredentials: null == proxyCredentials ? _self.proxyCredentials : proxyCredentials // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class HttpxCredentialsBearer implements HttpxCredentials {
  const HttpxCredentialsBearer({this.realm, required this.accessToken, this.proxyCredentials = false});
  

@override final  String? realm;
 final  String accessToken;
@override@JsonKey() final  bool proxyCredentials;

/// Create a copy of HttpxCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpxCredentialsBearerCopyWith<HttpxCredentialsBearer> get copyWith => _$HttpxCredentialsBearerCopyWithImpl<HttpxCredentialsBearer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpxCredentialsBearer&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.proxyCredentials, proxyCredentials) || other.proxyCredentials == proxyCredentials));
}


@override
int get hashCode => Object.hash(runtimeType,realm,accessToken,proxyCredentials);

@override
String toString() {
  return 'HttpxCredentials.bearer(realm: $realm, accessToken: $accessToken, proxyCredentials: $proxyCredentials)';
}


}

/// @nodoc
abstract mixin class $HttpxCredentialsBearerCopyWith<$Res> implements $HttpxCredentialsCopyWith<$Res> {
  factory $HttpxCredentialsBearerCopyWith(HttpxCredentialsBearer value, $Res Function(HttpxCredentialsBearer) _then) = _$HttpxCredentialsBearerCopyWithImpl;
@override @useResult
$Res call({
 String? realm, String accessToken, bool proxyCredentials
});




}
/// @nodoc
class _$HttpxCredentialsBearerCopyWithImpl<$Res>
    implements $HttpxCredentialsBearerCopyWith<$Res> {
  _$HttpxCredentialsBearerCopyWithImpl(this._self, this._then);

  final HttpxCredentialsBearer _self;
  final $Res Function(HttpxCredentialsBearer) _then;

/// Create a copy of HttpxCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? realm = freezed,Object? accessToken = null,Object? proxyCredentials = null,}) {
  return _then(HttpxCredentialsBearer(
realm: freezed == realm ? _self.realm : realm // ignore: cast_nullable_to_non_nullable
as String?,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,proxyCredentials: null == proxyCredentials ? _self.proxyCredentials : proxyCredentials // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
