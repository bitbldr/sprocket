import topbar from "topbar";
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
  oldVNode: VNode | Element | DocumentFragment,
  vnode: VNode
) => VNode;

type Opts = {
  hooks?: Record<string, any>;
  initialProps?: Record<string, string>;
  customEventEncoders?: Record<string, any>;
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
  const socket = new WebSocket(ws_protocol + "//" + location.host + path);

  let dom: Record<string, any>;
  let oldVNode: VNode;

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

  socket.addEventListener("open", function (event) {
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
          oldVNode = render(dom, providers) as VNode;

          // Patch the target element
          patcher(targetEl, oldVNode);

          break;

        case "update":
          // Apply the patch to the existing DOM
          const patch = parsed[1];
          const updateOpts = parsed[2];
          dom = applyPatch(dom, patch, updateOpts) as Element;

          // Update the target DOM element
          oldVNode = update(patcher, oldVNode, dom, providers);

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

    // Attempt to reconnect after a delay (e.g., 5 seconds)
    setTimeout(() => {
      console.log("Attempting to reconnect...");

      // Reinitialize the socket connection
      connect(path, oldVNode, csrfToken, opts);
    }, 5000);
  });
}

// update the target DOM element using a given JSON DOM
function update(
  patcher: Patcher,
  oldVNode: VNode,
  patched: Record<string, any>,
  providers: Providers
) {
  const rendered = render(patched, providers) as VNode;

  patcher(oldVNode, rendered);

  return rendered;
}
