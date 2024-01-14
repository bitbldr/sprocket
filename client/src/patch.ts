import { isInteger, htmlDecode } from "./utils";

enum OpCode {
  NoOp = 0,
  Update = 1,
  Replace = 2,
  Insert = 3,
  Remove = 4,
  Change = 5,
  Move = 6,
}

function getOperation(patch: Patch, debug: boolean): Operation {
  if (debug) {
    switch (patch[0]) {
      case "NoOp":
        return [OpCode.NoOp];
      case "Update":
        return [OpCode.Update, patch[1], patch[2]];
      case "Replace":
        return [OpCode.Replace, patch[1]];
      case "Insert":
        return [OpCode.Insert, patch[1]];
      case "Remove":
        return [OpCode.Remove];
      case "Change":
        return [OpCode.Change, patch[1]];
      case "Move":
        return [OpCode.Move, patch[1], patch[2]];
      default:
        throw new Error("Unknown op code: " + patch[0]);
    }
  }

  // in regular production mode op codes are compressed and sent as integer strings to save bytes
  switch (patch[0]) {
    case "0":
      return [OpCode.NoOp];
    case "1":
      return [OpCode.Update, patch[1], patch[2]];
    case "2":
      return [OpCode.Replace, patch[1]];
    case "3":
      return [OpCode.Insert, patch[1]];
    case "4":
      return [OpCode.Remove];
    case "5":
      return [OpCode.Change, patch[1]];
    case "6":
      return [OpCode.Move, patch[1], patch[2]];
    default:
      throw new Error("Unknown op code: " + patch[0]);
  }
}

type Attributes = Record<string, string> | null;
type Children = Record<string, Patch> | null;
type Element = Record<string, any>;

export type ProdPatch =
  | ["0"]
  | ["1", Attributes, Children]
  | ["2", Element]
  | ["3", Element]
  | ["4"]
  | ["5", string]
  | ["6", number, Patch];

export type DebugPatch =
  | ["NoOp"]
  | ["Update", Attributes, Children]
  | ["Replace", Element]
  | ["Insert", Element]
  | ["Remove"]
  | ["Change", string]
  | ["Move", number, Patch];

export type Patch = ProdPatch | DebugPatch;

export type Operation =
  | [OpCode.NoOp]
  | [OpCode.Update, Attributes, Children]
  | [OpCode.Replace, Element]
  | [OpCode.Insert, Element]
  | [OpCode.Remove]
  | [OpCode.Change, string]
  | [OpCode.Move, number, Patch];

export function applyPatch(
  original: Record<string, any>,
  patch: Patch,
  opts: Record<string, any>,
  parent?: Record<string, any>,
  currentKey?: string
): Record<string, any> | string | null {
  const operation = getOperation(patch, !!opts.debug);
  switch (operation[0]) {
    case OpCode.NoOp:
      return original;
    case OpCode.Update:
      const newAttrs = operation[1];
      const childrenPatchMap = operation[2];
      let updated = Object.assign({}, original);

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
            const childOperation = getOperation(patch, !!opts.debug);

            let newEl = applyPatch(
              updated[key],
              childrenPatchMap[key],
              opts,
              original,
              key
            );

            if (newEl) {
              if (childOperation[0] === OpCode.Move) {
                const fromKey = childOperation[1];
                delete updated[fromKey];
              }

              return {
                ...updated,
                [key]: newEl,
              };
            } else {
              delete updated[key];
            }

            return updated;
          }, updated);
      }

      return updated;
    case OpCode.Replace:
      return maybeHtmlDecode(operation[1]);
    case OpCode.Insert:
      return maybeHtmlDecode(operation[1]);
    case OpCode.Remove:
      return null;
    case OpCode.Change:
      return maybeHtmlDecode(operation[1]);
    case OpCode.Move:
      if (parent) {
        const fromKey = operation[1];

        const movedAndPatched = applyPatch(
          (parent as any)[fromKey],
          operation[2],
          opts,
          parent,
          currentKey
        );

        return movedAndPatched;
      } else {
        throw new Error("Cannot move element without parent");
      }
  }
}

function maybeHtmlDecode(maybeString) {
  if (typeof maybeString === "string") {
    return htmlDecode(maybeString);
  }

  return maybeString;
}
