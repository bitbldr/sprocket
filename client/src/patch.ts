enum OpCode {
  NoOp = 0,
  Update = 1,
  Replace = 2,
  Add = 3,
  Remove = 4,
  Change = 5,
  Move = 6,
}

type Attributes = { [key: string]: string };
type Children = { [key: string]: Patch };
type Element = Record<string, any>;

export type Patch =
  | [OpCode.NoOp]
  | [OpCode.Update, Attributes | null, Children | null]
  | [OpCode.Replace, Element]
  | [OpCode.Add, Element]
  | [OpCode.Remove]
  | [OpCode.Change, string]
  | [OpCode.Move, number, Patch];

export function applyPatch(
  original: Record<string, any>,
  patch: Patch,
  parent?: Record<string, any>,
  index?: number
): Record<string, any> | string | null {
  switch (patch[0]) {
    case OpCode.NoOp:
      return original;
    case OpCode.Update:
      let updated = original;

      if (patch[1]) {
        updated = {
          ...original,
          attrs: patch[1],
        };
      }

      if (patch[2]) {
        let current = 0;
        while (patch[2][current]) {
          let newEl = applyPatch(
            updated[current],
            patch[2][current],
            updated,
            current
          );

          if (newEl) {
            updated = {
              ...updated,
              [current]: newEl,
            };
          }

          current++;
        }
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
      const moved = (parent as any)[index as any];

      if (moved) {
        return applyPatch(moved, patch[2], parent, index);
      } else {
        throw new Error("Cannot move element without parent");
      }
  }
}
