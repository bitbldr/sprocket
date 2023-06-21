import { isInteger } from "./utils";

enum OpCode {
  NoOp = 0,
  Update = 1,
  Replace = 2,
  Add = 3,
  Remove = 4,
  Change = 5,
  Move = 6,
}

type Attributes = Record<string, string> | null;
type Children = Record<string, Patch> | null;
type Element = Record<string, any>;

export type Patch =
  | [OpCode.NoOp]
  | [OpCode.Update, Attributes, Children]
  | [OpCode.Replace, Element]
  | [OpCode.Add, Element]
  | [OpCode.Remove]
  | [OpCode.Change, string]
  | [OpCode.Move, number, Patch];

export function applyPatch(
  original: Record<string, any>,
  patch: Patch,
  parent?: Record<string, any>,
  currentKey?: string
): Record<string, any> | string | null {
  switch (patch[0]) {
    case OpCode.NoOp:
      return original;
    case OpCode.Update:
      const newAttrs = patch[1];
      const childrenPatchMap = patch[2];
      let updated = original;

      if (newAttrs) {
        updated = {
          ...updated,
          attrs: newAttrs,
        };
      }

      if (childrenPatchMap) {
        updated = Object.keys(childrenPatchMap)
          .filter((key) => isInteger(key))
          .reduce((updated, key) => {
            let newEl = applyPatch(
              updated[key],
              childrenPatchMap[key],
              updated,
              key
            );

            if (newEl) {
              return {
                ...updated,
                [key]: newEl,
              };
            }

            return updated;
          }, updated);
      }

      return updated;
    case OpCode.Replace:
      return patch[1];
    case OpCode.Add:
      return patch[1];
    case OpCode.Remove:
      return null;
    case OpCode.Change:
      return patch[1];
    case OpCode.Move:
      const moved = (parent as any)[currentKey as any];

      if (moved) {
        return applyPatch(moved, patch[2], parent, currentKey);
      } else {
        throw new Error("Cannot move element without parent");
      }
  }
}
