// Copyright 2015 Google Inc. All Rights Reserved.
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

library flow.loads;

import 'package:saga/src/flow/cpu_register.dart';
import 'package:saga/src/flow/node.dart';
import 'package:saga/src/flow/types.dart';

loadField(field, obj) {
  return new Node(new OpLoadField(field), [obj])..type = field.type;
}

class OpLoadField extends Op {
  final field;

  OpLoadField(this.field);
  get typeTag => "OpLoadField";

  format(inputs) => "${inputs[0]}.${field.name}";
}

const LOAD_ELEMENT = const SingletonOp("OpLoadElement");

loadElement(elementType, array, index) {
  return new Node(LOAD_ELEMENT, [array, index])..type = elementType;
}

typeLoads(state, blocks) {
  final heapBase = state.entryState[CpuRegister.R12];
  for (var use in iterate(heapBase.uses)) {
    if (use.idx == 0 &&
        use.at.op is OpAddr &&
        use.at.op.scale == 8 &&
        use.at.op.offset == 0) {
      use.at.replaceWith(Node.unpack(use.at.inputs[1].def));
    }
  }

  for (var block in blocks) {
    for (var node in iterate(block.code).where((node) => node.op == LOAD)) {
      final addr = node.inputs[0].def;

      if (addr.op is OpAddr) {
        final base = addr.inputs[0].def;
        final index = addr.inputs[1].def;

        if (base != null && base.op == UNPACK) {
          base.type = base.inputs[0].def.type;
        }

        if (base == heapBase &&
            addr.op.scale == 8 &&
            index.type is ReferenceType) {
          final field = index.type.fieldsByOffset[addr.op.offset];
          if (field != null) {
            final unpacked = Node.unpack(index);
            node.insertBefore(unpacked);
            node.replaceWith(loadField(field, unpacked));
          }
        } else if (base != null && base.type is ReferenceType) {
          if (index == null) {
            final field = base.type.fieldsByOffset[addr.op.offset];
            if (field != null) {
              node.replaceWith(loadField(field, base));
            }
          } else if (base.type is ArrayType) {
            final indexAdj = (addr.op.offset - ArrayType.elementsOffset) ~/ addr.op.scale;
            if (indexAdj != 0) {
              final adjustedIdx = Node.binary(ADD, index, Node.konst(indexAdj));
              node.insertBefore(adjustedIdx);
              node.replaceWith(loadElement(base.type.elementType, base, adjustedIdx));
            } else {
              node.replaceWith(loadElement(base.type.elementType, base, index));
            }
          }
        }
      }
    }
  }
}