// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

typedef HttpxHeaderName = String;
typedef HttpxHeaderValue = String;

typedef HttpxHeaderValues = Iterable<HttpxHeaderValue>;

typedef HttpxHeadersEntries = Map<HttpxHeaderName, HttpxHeaderValues>;

typedef HttpxHeadersFoldedEntries = Map<HttpxHeaderName, HttpxHeaderValue>;
