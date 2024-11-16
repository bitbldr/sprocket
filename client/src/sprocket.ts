import topbar from "topbar";
import {
  init,
  attributesModule,
  eventListenersModule,
  VNode,
  toVNode,
} from "snabbdom";
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
  csrfToken: string;
  targetEl?: Element;
  hooks?: Record<string, any>;
  initialProps?: Record<string, string>;
  customEventEncoders?: Record<string, any>;
};

export function connect(path: String, opts: Opts, existingVNode?: VNode) {
  const csrfToken = opts.csrfToken || new Error("Missing CSRF token");
  const targetEl = opts.targetEl || document.documentElement;

  let ws_protocol = location.protocol === "https:" ? "wss:" : "ws:";
  let socket = new WebSocket(ws_protocol + "//" + location.host + path);

  let oldVNode: VNode = existingVNode || toVNode(targetEl);
  let patched: Record<string, any>;

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

          patched = parsed[1];
          oldVNode = update(patcher, oldVNode, patched, providers);

          break;

        case "update":
          patched = applyPatch(patched, parsed[1], parsed[2]) as Element;

          oldVNode = update(patcher, oldVNode, patched, providers);

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

    setTimeout(() => {
      console.log("Attempting to reconnect...");

      // Reinitialize the socket connection, reuse the existing VNode
      connect(path, opts, oldVNode);
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

  return patcher(oldVNode, rendered);
}
