import { Module } from "snabbdom";

type PushEvent = (event: string, payload: any) => void;

type ElementId = string;
type HookName = string;

export type Hook = {
  el: Node;
  pushEvent: PushEvent;
  handleEvent: (event: string, handler: (payload: any) => any) => void;
  [key: string]: any;
};

export interface HookIdentifier {
  name: string;
}

type Emit = {
  id: ElementId;
  hook: HookName;
  kind: string;
  payload: any;
};

export type ClientHookProvider = {
  hook: (elementHooks: HookIdentifier[]) => Module;
  handle_emit: (emit: Emit) => void;
};

export const initClientHookProvider = (
  hooks: Record<string, any> = {},
  sendHookMsg: (
    elementId: string,
    hook: string,
    kind: string,
    payload: any
  ) => void
): ClientHookProvider => {
  let clientHookMap: Record<ElementId, Record<HookName, Hook>> = {};

  return {
    hook: (elementHooks: HookIdentifier[]) => ({
      create: (emptyVNode, vnode) => {
        const elementId = vnode.data.elementId;

        elementHooks.forEach((h) => {
          const { name: hookName } = h;

          const pushEvent = (kind: string, payload: any) =>
            sendHookMsg(vnode.data.elementId, hookName, kind, payload);

          const handleEvent = (
            kind: string,
            handler: (payload: any) => any
          ) => {
            clientHookMap[elementId][hookName].handlers = [
              ...(clientHookMap[elementId][hookName].handlers || []),
              { kind, handler },
            ];
          };

          // Initialize the client hook map if it doesn't already exist and add the hook
          clientHookMap[vnode.data.elementId] = {
            ...(clientHookMap[vnode.data.elementId] || {}),
            [hookName]: {
              el: vnode.elm,
              pushEvent,
              handleEvent,
            },
          };

          execClientHook(hooks, clientHookMap, elementId, hookName, "create");
        });
      },
      insert: (vnode) => {
        const elementId = vnode.data.elementId;

        elementHooks.forEach((h) => {
          const { name: hookName } = h;

          execClientHook(hooks, clientHookMap, elementId, hookName, "insert");
        });
      },
      update: (oldVNode, vnode) => {
        const elementId = vnode.data.elementId;

        // If the element id has changed, we need to update the client hook map to reflect the new element id
        if (oldVNode.data.elementId !== vnode.data.elementId) {
          // Move the hook state to the new element id
          clientHookMap[vnode.data.elementId] =
            clientHookMap[oldVNode.data.elementId];

          delete clientHookMap[oldVNode.data.elementId];
        }

        elementHooks.forEach((h) => {
          const { name: hookName } = h;

          // If the element id has changed, we also need to update the pushEvent function for each hook
          if (oldVNode.data.elementId !== vnode.data.elementId) {
            // Update the pushEvent function to use the new element id
            const pushEvent = (kind: string, payload: any) =>
              sendHookMsg(vnode.data.elementId, hookName, kind, payload);

            clientHookMap[vnode.data.elementId][hookName].pushEvent = pushEvent;
          }

          execClientHook(hooks, clientHookMap, elementId, hookName, "update");
        });
      },
      destroy: (vnode) => {
        const elementId = vnode.data.elementId;

        elementHooks.forEach((h) => {
          const { name: hookName } = h;

          execClientHook(hooks, clientHookMap, elementId, hookName, "destroy");

          delete clientHookMap[elementId];
        });
      },
    }),
    handle_emit: (emit) => {
      // find handler by elementId
      const { id: elementId, hook: hookName, kind: eventKind, payload } = emit;

      const handlers =
        clientHookMap[elementId] &&
        clientHookMap[elementId][hookName] &&
        clientHookMap[elementId][hookName].handlers;

      if (handlers) {
        handlers.forEach((h) => {
          if (h.kind === eventKind) {
            h.handler(payload);
          }
        });
      }
    },
  };
};

function execClientHook(
  hooks: Record<string, any>,
  clientHookMap: Record<string, any>,
  elementId: string,
  hookName: string,
  method: string
) {
  const hook = hooks[hookName];

  if (hook) {
    hook[method] &&
      hook[method].call(
        clientHookMap[elementId][hookName],
        clientHookMap[elementId][hookName]
      );
  } else {
    throw new Error(`Client hook ${hookName} not found`);
  }
}
