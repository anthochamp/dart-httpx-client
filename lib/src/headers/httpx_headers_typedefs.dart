// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

typedef HttpxHeaderName = String;
typedef HttpxHeaderValue = String;

typedef HttpxHeaderValues = Iterable<HttpxHeaderValue>;

typedef HttpxHeadersEntries = Map<HttpxHeaderName, HttpxHeaderValues>;

typedef HttpxHeadersFoldedEntries = Map<HttpxHeaderName, HttpxHeaderValue>;
