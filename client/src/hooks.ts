import ReconnectingWebSocket from "reconnecting-websocket";
import { Module } from "snabbdom";

type PushEvent = (event: string, payload: any) => void;

export type Hook = {
  el: Node;
  pushEvent: PushEvent;
  handleEvent: (event: string, handler: (payload: any) => any) => void;
  [key: string]: any;
};

export interface HookIdentifier {
  name: string;
  id: string;
}

export type ClientHookProvider = (elementHooks: HookIdentifier[]) => Module;

export const initClientHookProvider = (
  socket: ReconnectingWebSocket,
  hooks: Record<string, any> = {}
): ClientHookProvider => {
  let clientHookMap: Record<string, Hook> = {};

  return (elementHooks: HookIdentifier[]) => ({
    create: (emptyVNode, vnode) => {
      elementHooks.forEach((h) => {
        const { id: hookId, name: hookName } = h;

        const pushEvent = (name: string, payload: any) => {
          socket.send(
            JSON.stringify(["hook:event", { id: hookId, name, payload }])
          );
        };

        const handleEvent = (event: string, handler: (payload: any) => any) => {
          socket.addEventListener("message", function (msg) {
            let parsed = JSON.parse(msg.data);

            if (Array.isArray(parsed)) {
              switch (parsed[0]) {
                case "hook:event":
                  if (parsed[1].id === hookId && parsed[1].kind === event) {
                    handler(parsed[1].payload);
                  }
                  break;
              }
            }
          });
        };

        clientHookMap[hookId] = {
          el: vnode.elm,
          pushEvent,
          handleEvent,
        };

        execClientHook(hooks, clientHookMap, hookName, hookId, "create");
      });
    },
    insert: (vnode) => {
      elementHooks.forEach((h) => {
        const { id: hookId, name: hookName } = h;

        execClientHook(hooks, clientHookMap, hookName, hookId, "insert");
      });
    },
    update: (oldVNode, vnode) => {
      elementHooks.forEach((h) => {
        const { id: hookId, name: hookName } = h;

        execClientHook(hooks, clientHookMap, hookName, hookId, "update");
      });
    },
    destroy: (vnode) => {
      elementHooks.forEach((h) => {
        const { id: hookId, name: hookName } = h;

        execClientHook(hooks, clientHookMap, hookName, hookId, "destroy");

        delete clientHookMap[hookId];
      });
    },
  });
};

function execClientHook(
  hooks: Record<string, any>,
  clientHookMap: Record<string, any>,
  hookName: string,
  hookId: string,
  method: string
) {
  const hook = hooks[hookName];

  if (hook) {
    hook[method] &&
      hook[method].call(clientHookMap[hookId], clientHookMap[hookId]);
  } else {
    throw new Error(`Client hook ${hookName} not found`);
  }
}
