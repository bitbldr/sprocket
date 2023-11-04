import morphdom from "morphdom";
import topbar from "topbar";
import ReconnectingWebSocket from "reconnecting-websocket";
import { renderDom } from "./render";
import { applyPatch } from "./patch";
import { initEventHandlers } from "./events";
import { constant } from "./constants";
import {
  processClientHookMount,
  processClientHookLifecycle,
  processClientHookDestroyed,
} from "./hooks";

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

          update(targetEl, dom, hooks, clientHookMap);

          // mount client hooks and initialize clientHookMap after the first render
          if (!clientHookMap) {
            clientHookMap = processClientHookMount(socket, hooks);
          }

          break;

        case "update":
          dom = applyPatch(dom, parsed[1], parsed[2]) as Element;

          update(targetEl, dom, hooks, clientHookMap);

          break;

        case "error":
          const { code, msg } = parsed[1];
          console.error(`Error ${code}: ${msg}`);

          switch (code) {
            case "preflight_not_found":
              setTimeout(() => window.location.reload(), 1000);
              break;
          }

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
function update(targetEl, dom, hooks, clientHookMap) {
  morphdom(targetEl, renderDom(dom), {
    onBeforeElUpdated: function (fromEl, toEl) {
      if (toEl.hasAttribute(constant.IgnoreUpdate)) return false;

      clientHookMap &&
        processClientHookLifecycle("beforeUpdate", hooks, clientHookMap, toEl);

      return true;
    },
    onElUpdated: function (el) {
      clientHookMap &&
        processClientHookLifecycle("updated", hooks, clientHookMap, el);
    },
    onNodeDiscarded: function (node) {
      if (node.nodeType == Node.ELEMENT_NODE) {
        const el = node as Element;

        clientHookMap =
          clientHookMap && processClientHookDestroyed(hooks, clientHookMap, el);
      }
    },
    getNodeKey: function (node) {
      if (node.nodeType == Node.ELEMENT_NODE) {
        const el = node as Element;
        if (el.hasAttribute(constant.KeyAttr)) {
          return el.getAttribute(constant.KeyAttr);
        }
      }
    },
  });
}
