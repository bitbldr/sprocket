import { Module, VNode } from "snabbdom";
import ReconnectingWebSocket from "reconnecting-websocket";
import { constant } from "../constants";

export const initClientHooksModule = (
  socket: ReconnectingWebSocket,
  hooks: Record<string, any>
): Module => {
  let clientHookMap: Record<string, any> = {};

  return {
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

        hooks[hookName].create && hooks[hookName].create(clientHookMap[hookId]);
      }
    },
    update: (oldVNode, vnode) => {
      const h = maybeGetHook(vnode);

      if (h) {
        const { id: hookId, name: hookName } = h;

        hooks[hookName].update && hooks[hookName].update(clientHookMap[hookId]);
      }
    },
    destroy: (vnode) => {
      const h = maybeGetHook(vnode);

      if (h) {
        const { id: hookId, name: hookName } = h;
        hooks[hookName].destroy &&
          hooks[hookName].destroy(clientHookMap[hookId]);

        delete clientHookMap[hookId];
      }
    },
  };
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
