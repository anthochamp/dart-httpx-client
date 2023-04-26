import 'dart:async';

abstract class HttpxPushMessage {}

abstract class HttpxPushStream implements Stream<HttpxPushMessage> {
  FutureOr<void> open();

  FutureOr<void> close();
}
