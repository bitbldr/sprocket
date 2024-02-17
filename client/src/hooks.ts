import { Module, VNode } from "snabbdom";
import ReconnectingWebSocket from "reconnecting-websocket";
import { constant } from "./constants";

type PushEvent = (event: string, payload: any) => void;

export type Hook = {
  el: Element;
  pushEvent: PushEvent;
  handleEvent: (event: string, handler: (payload: any) => any) => void;
};

export type ClientHookProvider = () => Module;

export const initClientHookProvider = (
  socket: ReconnectingWebSocket,
  hooks: Record<string, any>,
  clientHookMap: Record<string, any>
): ClientHookProvider => {
  return () => ({
    create: (emptyVNode, vnode) => {
      const h = maybeGetHook(vnode);

      if (h) {
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
          name: hookName,
          pushEvent,
          handleEvent,
        };

        execClientHook(hooks, clientHookMap, hookName, hookId, "create");
      }
    },
    insert: (vnode) => {
      const h = maybeGetHook(vnode);

      if (h) {
        const { id: hookId, name: hookName } = h;
        execClientHook(hooks, clientHookMap, hookName, hookId, "insert");
      }
    },
    update: (oldVNode, vnode) => {
      const h = maybeGetHook(vnode);

      if (h) {
        const { id: hookId, name: hookName } = h;
        execClientHook(hooks, clientHookMap, hookName, hookId, "update");
      }
    },
    destroy: (vnode) => {
      const h = maybeGetHook(vnode);

      if (h) {
        const { id: hookId, name: hookName } = h;
        execClientHook(hooks, clientHookMap, hookName, hookId, "destroy");

        delete clientHookMap[hookId];
      }
    },
  });
};

function maybeGetHook(vnode: VNode) {
  const attrs = vnode?.data?.attrs;

  const name = attrs && (attrs[`${constant.HookAttrPrefix}`] as string);
  const id = attrs && (attrs[`${constant.HookAttrPrefix}-id`] as string);

  if (id && name) {
    return { id, name };
  }

  return null;
}

function execClientHook(
  hooks: Record<string, any>,
  clientHookMap: Record<string, any>,
  hookName: string,
  hookId: string,
  method: string
) {
  const hook = hooks[hookName];

  if (hook) {
    hook[method] && hook[method](clientHookMap[hookId]);
  } else {
    throw new Error(`Client hook ${hookName} not found`);
  }
}
