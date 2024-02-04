// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

abstract class HttpxPushMessage {}

abstract class HttpxPushStream implements Stream<HttpxPushMessage> {
  FutureOr<void> open();

  FutureOr<void> close();
}
