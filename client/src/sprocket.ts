import topbar from "topbar";
import ReconnectingWebSocket from "reconnecting-websocket";
import { init, attributesModule, eventListenersModule, VNode } from "snabbdom";
import { render, Providers } from "./render";
import { applyPatch } from "./patch";
import { initEventHandlerProvider } from "./events";
import { initClientHookProvider, Hook } from "./hooks";
import { rawHtmlModule } from "./modules/rawHtml";

export type ClientHook = {
  create?: (hook: Hook) => void;
  insert?: (hook: Hook) => void;
  update?: (hook: Hook) => void;
  destroy?: (hook: Hook) => void;
};

type Patcher = (
  currentVNode: VNode | Element | DocumentFragment,
  vnode: VNode
) => VNode;

type Opts = {
  hooks?: Record<string, any>;
  initialProps?: Record<string, string>;
  customEventEncoders?: Record<string, any>;
  reconnectAttempt?: number;
};

export function connect(
  path: String,
  targetEl: Element | VNode,
  csrfToken: string,
  opts: Opts
) {
  if (!targetEl) throw new Error("targetEl is required");
  if (!csrfToken) throw new Error("csrfToken is required");

  const ws_protocol = location.protocol === "https:" ? "wss:" : "ws:";
  const socket = new ReconnectingWebSocket(
    ws_protocol + "//" + location.host + path
  );

  let dom: Record<string, any>;
  let currentVNode: VNode;
  let firstConnect = true;

  const patcher = init(
    [attributesModule, eventListenersModule, rawHtmlModule],
    undefined,
    {
      experimental: {
        fragments: true,
      },
    }
  );

  const clientHookProvider = initClientHookProvider(socket, opts.hooks);

  const eventHandlerProvider = initEventHandlerProvider(
    socket,
    opts.customEventEncoders
  );

  const providers: Providers = {
    clientHookProvider,
    eventHandlerProvider,
  };

  topbar.config({ barColors: { 0: "#29d" }, barThickness: 2 });
  topbar.show(500);

  socket.addEventListener("open", function (_event) {
    socket.send(
      JSON.stringify([
        "join",
        { csrf: csrfToken, initialProps: opts.initialProps },
      ])
    );
  });

  socket.addEventListener("message", function (event) {
    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "ok":
          topbar.hide();

          // Render the full initial DOM
          dom = parsed[1];
          const rendered = render(dom, providers) as VNode;

          if (firstConnect) {
            firstConnect = false;

            // Patch the target element
            patcher(targetEl, rendered);
          } else {
            // Patch the currentVNode element
            patcher(currentVNode, rendered);
          }

          currentVNode = rendered;

          break;

        case "update":
          // Apply the patch to the existing DOM
          const patch = parsed[1];
          const updateOpts = parsed[2];
          dom = applyPatch(dom, patch, updateOpts) as Element;

          // Update the target DOM element
          currentVNode = update(patcher, currentVNode, dom, providers);

          break;

        case "hook:event":
          clientHookProvider.handle_message(event);

          break;

        case "error":
          const { code, msg } = parsed[1];
          console.error(`Error ${code}: ${msg}`);

          break;
      }
    }
  });

  socket.addEventListener("close", function (_event) {
    topbar.show();
  });
}

// update the target DOM element using a given JSON DOM
function update(
  patcher: Patcher,
  currentVNode: VNode,
  patched: Record<string, any>,
  providers: Providers
) {
  const rendered = render(patched, providers) as VNode;

  patcher(currentVNode, rendered);

  return rendered;
}
