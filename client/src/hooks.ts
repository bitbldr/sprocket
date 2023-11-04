import ReconnectingWebSocket from "reconnecting-websocket";
import { constant } from "./constants";

export type PushEvent = (event: string, payload: any) => void;

export type ClientHook = {
  el: Element;
  name: string;
  pushEvent: PushEvent;
  handleEvent: (event: string, handler: (payload: any) => any) => void;
};

export type ClientHookSpec = {
  mounted?: (hook: ClientHook) => void;
  beforeUpdate?: (hook: ClientHook) => void;
  updated?: (hook: ClientHook) => void;
  destroyed?: (hook: ClientHook) => void;
  disconnected?: (hook: ClientHook) => void;
  reconnected?: (hook: ClientHook) => void;
};

export function processClientHookMount(
  socket: ReconnectingWebSocket,
  hooks: Record<string, ClientHookSpec>
): Record<string, ClientHook> {
  // handle hook lifecycle mounted events, return a clientHookMap
  return Object.keys(hooks).reduce((clientHookMap, name) => {
    if (hooks[name].mounted) {
      return Array.from(
        document.querySelectorAll(`[${constant.HookAttrPrefix}=${name}]`)
      ).reduce((clientHookMap, el) => {
        const hookId = el.getAttribute(`${constant.HookAttrPrefix}-id`);

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

        clientHookMap[hookId] = { el, name, pushEvent, handleEvent };

        hooks[name].mounted(clientHookMap[hookId]);

        return clientHookMap;
      }, {});
    }

    return clientHookMap;
  }, {});
}

export function processClientHookLifecycle(
  lifecycle: keyof ClientHookSpec,
  hooks: Record<string, ClientHookSpec>,
  clientHookMap: Record<string, ClientHook>,
  el: Element
) {
  const hookId = el.getAttribute(`${constant.HookAttrPrefix}-id`);

  if (hookId && clientHookMap[hookId]) {
    const hook = clientHookMap[hookId];

    if (hooks[hook.name][lifecycle]) {
      hooks[hook.name][lifecycle](hook);
    }
  }
}

export function processClientHookDestroyed(
  hooks: Record<string, ClientHookSpec>,
  clientHookMap: Record<string, ClientHook>,
  el: Element
): Record<string, ClientHook> {
  const hookId = el.getAttribute(`${constant.HookAttrPrefix}-id`);

  if (hookId && clientHookMap[hookId]) {
    const hook = clientHookMap[hookId];

    if (hooks[hook.name].destroyed) {
      hooks[hook.name].destroyed(hook);

      delete clientHookMap[hookId];

      return clientHookMap;
    }
  }

  return clientHookMap;
}
