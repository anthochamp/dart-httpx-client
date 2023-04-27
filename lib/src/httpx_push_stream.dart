// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

abstract class HttpxPushMessage {}

abstract class HttpxPushStream implements Stream<HttpxPushMessage> {
  FutureOr<void> open();

  FutureOr<void> close();
}
