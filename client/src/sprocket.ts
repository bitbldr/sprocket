import topbar from "topbar";
import ReconnectingWebSocket from "reconnecting-websocket";
import { init, attributesModule, VNode, toVNode } from "snabbdom";
import { render } from "./render";
import { applyPatch } from "./patch";
import { initEventHandlers } from "./events";
import { initClientHooksModule } from "./modules/clientHooksModule";

export { ClientHook } from "./hooks";

type Patcher = (
  oldVNode: VNode | Element | DocumentFragment,
  vnode: VNode
) => VNode;

type Opts = {
  csrfToken: string;
  targetEl?: Element;
  hooks?: Record<string, any>;
};

export function connect(path: String, opts: Opts) {
  const csrfToken = opts.csrfToken || new Error("Missing CSRF token");
  const targetEl = opts.targetEl || document.documentElement;
  const hooks = opts.hooks || {};

  let ws_protocol = location.protocol === "https:" ? "wss:" : "ws:";
  const socket = new ReconnectingWebSocket(
    ws_protocol + "//" + location.host + path
  );

  let dom: Record<string, any>;
  let oldVNode: VNode;

  const patcher = init(
    [attributesModule, initClientHooksModule(socket, hooks)],
    undefined,
    {
      experimental: {
        fragments: true,
      },
    }
  );

  topbar.config({ barColors: { 0: "#29d" }, barThickness: 2 });
  topbar.show(500);

  socket.addEventListener("open", function (event) {
    socket.send(JSON.stringify(["join", { csrf: csrfToken }]));
  });

  socket.addEventListener("message", function (event) {
    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "ok":
          topbar.hide();

          dom = parsed[1];

          oldVNode = update(patcher, toVNode(targetEl), dom);

          break;

        case "update":
          dom = applyPatch(dom, parsed[1], parsed[2]) as Element;

          oldVNode = update(patcher, oldVNode, dom);

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

  // wire up event handlers
  initEventHandlers(socket);
}

// update the target DOM element using a given JSON DOM
function update(
  patcher: Patcher,
  oldVNode: VNode,
  patched: Record<string, any>
) {
  const rendered = render(patched) as VNode;

  patcher(oldVNode, rendered);

  return rendered;
}
