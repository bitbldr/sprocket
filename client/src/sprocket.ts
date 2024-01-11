import topbar from "topbar";
import ReconnectingWebSocket from "reconnecting-websocket";
import { init, attributesModule, VNode, toVNode } from "snabbdom";
import { render } from "./render";
import { applyPatch } from "./patch";
import { initEventHandlers } from "./events";
import { constant } from "./constants";
import {
  processClientHookMount,
  processClientHookLifecycle,
  processClientHookDestroyed,
} from "./hooks";

const patchDOM = init([attributesModule], undefined, {
  experimental: {
    fragments: true,
  },
});

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
  let clientHookMap: Record<string, any>;

  topbar.config({ barColors: { 0: "#29d" }, barThickness: 2 });
  topbar.show(500);

  socket.addEventListener("open", function (event) {
    socket.send(JSON.stringify(["join", { csrf: csrfToken }]));

    if (clientHookMap) {
      processClientHookLifecycle("reconnected", hooks, clientHookMap, targetEl);
    }
  });

  socket.addEventListener("message", function (event) {
    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "ok":
          topbar.hide();

          dom = parsed[1];

          oldVNode = update(toVNode(targetEl), dom, hooks, clientHookMap);

          // mount client hooks and initialize clientHookMap after the first render
          if (!clientHookMap) {
            clientHookMap = processClientHookMount(socket, hooks);
          }

          break;

        case "update":
          dom = applyPatch(dom, parsed[1], parsed[2]) as Element;

          oldVNode = update(oldVNode, dom, hooks, clientHookMap);

          break;

        case "error":
          const { code, msg } = parsed[1];
          console.error(`Error ${code}: ${msg}`);

          break;
      }
    }
  });

  socket.addEventListener("close", function (event) {
    processClientHookLifecycle("disconnected", hooks, clientHookMap, targetEl);

    topbar.show();
  });

  // wire up event handlers
  initEventHandlers(socket);
}

// update the target DOM element using a given JSON DOM
function update(
  oldVNode: VNode,
  patched: Record<string, any>,
  hooks: Record<string, any>,
  clientHookMap: Record<string, any>
) {
  const rendered = render(patched) as VNode;
  const html = rendered.children[0] as VNode;

  patchDOM(oldVNode, html);

  return html;

  // morphdom(targetEl, renderDom(dom), {
  //   onBeforeElUpdated: function (fromEl, toEl) {
  //     if (toEl.hasAttribute(constant.IgnoreUpdate)) return false;
  //     clientHookMap &&
  //       processClientHookLifecycle("beforeUpdate", hooks, clientHookMap, toEl);
  //     return true;
  //   },
  //   onElUpdated: function (el) {
  //     clientHookMap &&
  //       processClientHookLifecycle("updated", hooks, clientHookMap, el);
  //   },
  //   onNodeDiscarded: function (node) {
  //     if (node.nodeType == Node.ELEMENT_NODE) {
  //       const el = node as Element;
  //       clientHookMap =
  //         clientHookMap && processClientHookDestroyed(hooks, clientHookMap, el);
  //     }
  //   },
  //   getNodeKey: function (node) {
  //     if (node.nodeType == Node.ELEMENT_NODE) {
  //       const el = node as Element;
  //       if (el.hasAttribute(constant.KeyAttr)) {
  //         return el.getAttribute(constant.KeyAttr);
  //       }
  //     }
  //   },
  // });
}
