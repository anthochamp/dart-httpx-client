// SPDX-FileCopyrightText: © 2026 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:ac_httpx_client/ac_httpx_client.dart';

Future<void> main() async {
  final client = HttpxClient();

  // --- Simple GET request ---
  print('--- GET request ---');

  final request = client.createRequest(
    uri: Uri.parse('https://httpbin.org/get'),
    method: 'GET',
  );

  final response = await request.close();
  print('Status: ${response.status} ${response.statusText}');
  print('Content-Type: ${response.headers['content-type']}');

  final body = await response.fold<List<int>>(
    [],
    (buffer, chunk) => buffer..addAll(chunk),
  );
  final text = utf8.decode(body);
  print('Body (truncated): ${text.substring(0, text.length.clamp(0, 200))}');

  // --- POST request with JSON body ---
  print('\n--- POST request ---');

  final postRequest = client.createRequest(
    uri: Uri.parse('https://httpbin.org/post'),
    method: 'POST',
    headers: HttpxHeaders.fromMap({'content-type': 'application/json'}),
  );

  final payload = utf8.encode('{"message":"hello"}');
  await postRequest.write(payload);
  final postResponse = await postRequest.close();
  print('Status: ${postResponse.status} ${postResponse.statusText}');
  await postResponse.dispose();
}
