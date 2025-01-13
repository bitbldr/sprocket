import ReconnectingWebSocket from "reconnecting-websocket";
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

export type ClientHookProvider = (elementHooks: HookIdentifier[]) => Module;

export const initClientHookProvider = (
  socket: ReconnectingWebSocket,
  hooks: Record<string, any> = {}
): ClientHookProvider => {
  let clientHookMap: Record<ElementId, Record<HookName, Hook>> = {};

  return (elementHooks: HookIdentifier[]) => ({
    create: (emptyVNode, vnode) => {
      const elementId = vnode.data.elementId;

      elementHooks.forEach((h) => {
        const { name: hookName } = h;

        const pushEvent = (kind: string, payload: any) => {
          socket.send(
            JSON.stringify([
              "hook:event",
              { id: vnode.data.elementId, hook: hookName, kind, payload },
            ])
          );
        };

        const handleEvent = (kind: string, handler: (payload: any) => any) => {
          socket.addEventListener("message", function (msg) {
            let parsed = JSON.parse(msg.data);

            if (Array.isArray(parsed)) {
              switch (parsed[0]) {
                case "hook:event":
                  if (
                    parsed[1].id === elementId &&
                    // parsed[1].name === hookName
                    parsed[1].kind === kind
                  ) {
                    handler(parsed[1].payload);
                  }
                  break;
              }
            }
          });
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

      elementHooks.forEach((h) => {
        const { name: hookName } = h;

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
  });
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
