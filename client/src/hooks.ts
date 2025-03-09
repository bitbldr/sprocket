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

type HookMessage = {
  id: ElementId;
  hook: HookName;
  kind: string;
  payload: any;
};

export type ClientHookProvider = {
  hook: (elementHooks: HookIdentifier[]) => Module;
  handle_message: (msg: HookMessage) => void;
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
          const { name } = h;

          const pushEvent = (kind: string, payload: any) =>
            sendHookMsg(vnode.data.elementId, name, kind, payload);

          const handleEvent = (
            kind: string,
            handler: (payload: any) => any
          ) => {
            clientHookMap[elementId][name].handlers = [
              ...(clientHookMap[elementId][name].handlers || []),
              { kind, handler },
            ];
          };

          // Initialize the client hook map if it doesn't already exist and add the hook
          clientHookMap[vnode.data.elementId] = {
            ...(clientHookMap[vnode.data.elementId] || {}),
            [name]: {
              el: vnode.elm,
              pushEvent,
              handleEvent,
            },
          };

          execClientHook(hooks, clientHookMap, elementId, name, "create");
        });
      },
      insert: (vnode) => {
        const elementId = vnode.data.elementId;

        elementHooks.forEach((h) => {
          const { name } = h;

          execClientHook(hooks, clientHookMap, elementId, name, "insert");
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

          // we also need to update the el and pushEvent function for each hook
          elementHooks.forEach((h) => {
            const { name } = h;

            clientHookMap[vnode.data.elementId][name].el = vnode.elm;

            // Update the pushEvent function to use the new element id
            const pushEvent = (kind: string, payload: any) =>
              sendHookMsg(vnode.data.elementId, name, kind, payload);

            clientHookMap[vnode.data.elementId][name].pushEvent = pushEvent;
          });
        }

        elementHooks.forEach((h) => {
          const { name } = h;

          execClientHook(hooks, clientHookMap, elementId, name, "update");
        });
      },
      destroy: (vnode) => {
        const elementId = vnode.data.elementId;

        elementHooks.forEach((h) => {
          const { name } = h;

          execClientHook(hooks, clientHookMap, elementId, name, "destroy");

          delete clientHookMap[elementId];
        });
      },
    }),
    handle_message: (msg) => {
      // find handler by elementId
      const { id: elementId, hook: name, kind: eventKind, payload } = msg;

      const handlers =
        clientHookMap[elementId] &&
        clientHookMap[elementId][name] &&
        clientHookMap[elementId][name].handlers;

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
  name: string,
  method: string
) {
  const hook = hooks[name];

  if (hook) {
    hook[method] &&
      hook[method].call(
        clientHookMap[elementId][name],
        clientHookMap[elementId][name]
      );
  } else {
    throw new Error(`Client hook ${name} not found`);
  }
}
