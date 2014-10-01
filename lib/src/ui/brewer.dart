// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/** Selecting colors from the brewer palette. */
library ui.brewer;

import 'dart:math' as math;

/** Palette generated by http://www.colorbrewer2.org/. */
final PALETTE = [
  /* "#FFF5F0", "#FEE0D2" ,*/ "#FCBBA1", "#FC9272", "#FB6A4A",
  "#EF3B2C", "#CB181D", "#A50F15", "#67000D"
];

colorFor(value, min, max) {
  final ratio = (value - min) / (max - min);
  return PALETTE[
    math.min((ratio * PALETTE.length).ceil(),
             PALETTE.length - 1)];

}