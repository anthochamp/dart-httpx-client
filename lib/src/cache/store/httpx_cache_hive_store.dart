// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: prefer-moving-to-variable

import 'dart:async';

import 'package:hive/hive.dart';

import '../../headers/httpx_headers.dart';
import '../../headers/httpx_headers_typedefs.dart';
import '../../httpx_redirect_info.dart';
import 'httpx_cache_store.dart';
import 'httpx_cache_store_entry.dart';

class _HiveRecord {
  final HttpxCacheStorePk primaryKey;

  final List<HttpxCacheStoreEntry> entries;

  _HiveRecord({required this.primaryKey, required this.entries});
}

class _TypeAdapterRecord extends TypeAdapter<_HiveRecord> {
  @override
  final int typeId;

  _TypeAdapterRecord(this.typeId);

  @override
  _HiveRecord read(BinaryReader reader) {
    final primaryKey = Uri.parse(reader.readString());
    final entries = reader.readList().cast<HttpxCacheStoreEntry>();

    return _HiveRecord(primaryKey: primaryKey, entries: entries);
  }

  @override
  void write(BinaryWriter writer, _HiveRecord obj) {
    writer.writeString(obj.primaryKey.toString());
    writer.writeList(obj.entries);
  }
}

class _TypeAdapterRedirectInfo extends TypeAdapter<HttpxRedirectInfo> {
  @override
  final int typeId;

  _TypeAdapterRedirectInfo(this.typeId);

  @override
  HttpxRedirectInfo read(BinaryReader reader) {
    final method = reader.readString();
    final statusCode = reader.readInt32();
    final location = Uri.parse(reader.readString());

    return HttpxRedirectInfo(
      method: method,
      statusCode: statusCode,
      location: location,
    );
  }

  @override
  void write(BinaryWriter writer, HttpxRedirectInfo obj) {
    writer.writeString(obj.method);
    writer.writeInt32(obj.statusCode);
    writer.writeString(obj.location.toString());
  }
}

class _TypeAdapterStoreEntry extends TypeAdapter<HttpxCacheStoreEntry> {
  @override
  final int typeId;

  _TypeAdapterStoreEntry(this.typeId);

  @override
  HttpxCacheStoreEntry read(BinaryReader reader) {
    final firstByteSentTime = DateTime.fromMicrosecondsSinceEpoch(
      reader.readInt(),
      isUtc: true,
    );
    final uri = Uri.parse(reader.readString());
    final requestHeaders = HttpxHeaders.fromMap(
      reader.readMap()
      // ignore: unnecessary_lambdas
      .map((key, value) => MapEntry<String, String>(key, value)),
    );
    final firstByteReceivedTime = DateTime.fromMicrosecondsSinceEpoch(
      reader.readInt(),
      isUtc: true,
    );
    final redirects = reader.readList().cast<HttpxRedirectInfo>();
    final status = reader.readInt32();
    final statusTextNull = reader.readBool();
    final statusText = statusTextNull ? null : reader.readString();
    final responseHeaders = HttpxHeaders.fromMap(
      reader.readMap()
      // ignore: unnecessary_lambdas
      .map((key, value) => MapEntry<String, String>(key, value)),
    );
    final responseBodyNull = reader.readBool();
    final responseBody = responseBodyNull ? null : reader.readIntList();

    return HttpxCacheStoreEntry(
      firstByteSentTime: firstByteSentTime,
      uri: uri,
      requestHeaders: requestHeaders,
      firstByteReceivedTime: firstByteReceivedTime,
      redirects: redirects,
      status: status,
      statusText: statusText,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
    );
  }

  @override
  void write(BinaryWriter writer, HttpxCacheStoreEntry obj) {
    writer.writeInt(obj.firstByteSentTime.microsecondsSinceEpoch);
    writer.writeString(obj.uri.toString());
    writer.writeMap(
      obj.requestHeaders.getFoldedEntries(lowerCasedNames: false),
    );
    writer.writeInt(obj.firstByteReceivedTime.microsecondsSinceEpoch);
    writer.writeList(obj.redirects.toList());
    writer.writeInt32(obj.status);
    writer.writeBool(obj.statusText == null);
    if (obj.statusText != null) {
      writer.writeString(obj.statusText!);
    }
    writer.writeMap(
      obj.responseHeaders.getFoldedEntries(lowerCasedNames: false),
    );
    writer.writeBool(obj.responseBody == null);
    if (obj.responseBody != null) {
      writer.writeIntList(obj.responseBody!);
    }
  }
}

class HttpxCacheHiveStore implements HttpxCacheStore {
  static const defaultBoxName = 'httpx_cache';

  final String boxName;
  final String boxPath;
  final HiveCipher? encryptionCipher;

  HttpxCacheHiveStore({
    this.boxName = defaultBoxName,
    required this.boxPath,
    this.encryptionCipher,
    int storeEntryHiveTypeId = 1,
    int recordHiveTypeId = 2,
    int redirectInfoHiveTypeId = 3,
  }) {
    if (!Hive.isAdapterRegistered(storeEntryHiveTypeId)) {
      Hive.registerAdapter(_TypeAdapterStoreEntry(storeEntryHiveTypeId));
    }
    if (!Hive.isAdapterRegistered(recordHiveTypeId)) {
      Hive.registerAdapter(_TypeAdapterRecord(recordHiveTypeId));
    }
    if (!Hive.isAdapterRegistered(redirectInfoHiveTypeId)) {
      Hive.registerAdapter(_TypeAdapterRedirectInfo(redirectInfoHiveTypeId));
    }
  }

  LazyBox<_HiveRecord>? _box;

  Future<void> open() async {
    _box = await Hive.openLazyBox(
      boxName,
      encryptionCipher: encryptionCipher,
      path: boxPath,
    );
  }

  FutureOr<void> close() => _box?.close();

  Future<void> clear() async {
    if (_box == null) {
      throw StateError('Store is not opened');
    }

    await _box!.clear();
  }

  @override
  Future<Iterable<HttpxCacheStoreEntry>> getAll(
    HttpxCacheStorePk primaryKey,
  ) async {
    if (_box == null) {
      throw StateError('Store is not opened');
    }

    final record = await _box!.get(primaryKey.toString());

    return record?.entries ?? <HttpxCacheStoreEntry>[];
  }

  @override
  Future<void> add(HttpxCacheStoreEntry entry) async {
    if (_box == null) {
      throw StateError('Store is not opened');
    }

    final primaryKey = HttpxCacheStore.composePrimaryKey(entry.uri);

    final record =
        await _box!.get(primaryKey.toString()) ??
        _HiveRecord(primaryKey: primaryKey, entries: []);

    record.entries.add(
      HttpxCacheStoreEntry(
        firstByteReceivedTime: entry.firstByteReceivedTime,
        firstByteSentTime: entry.firstByteSentTime,
        redirects: entry.redirects,
        requestHeaders: entry.requestHeaders,
        responseBody: entry.responseBody,
        responseHeaders: entry.responseHeaders,
        status: entry.status,
        statusText: entry.statusText,
        uri: entry.uri,
      ),
    );

    await _box?.put(primaryKey.toString(), record);
  }

  @override
  Future<void> removeWhere({
    required HttpxCacheStorePk primaryKey,
    HttpxHeadersEntries? requestHeadersFilter,
    HttpxHeadersEntries? responseHeadersFilter,
  }) async {
    final record = await _box!.get(primaryKey.toString());

    record?.entries.removeWhere((cacheEntry) {
      if (requestHeadersFilter != null &&
          !cacheEntry.requestHeaders.matchAll(requestHeadersFilter)) {
        return false;
      }

      if (responseHeadersFilter != null &&
          !cacheEntry.responseHeaders.matchAll(responseHeadersFilter)) {
        return false;
      }

      return true;
    });

    if (record != null) {
      await _box?.put(primaryKey.toString(), record);
    }
  }
}
