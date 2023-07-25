import morphdom from "morphdom";
import topbar from "topbar";
import { renderDom } from "./render";
import { applyPatch } from "./patch";
import { initEventHandlers } from "./events";
import { constant } from "./constants";

window.addEventListener("DOMContentLoaded", () => {
  let ws_protocol = location.protocol === "https:" ? "wss:" : "ws:";
  const socket = new WebSocket(ws_protocol + "//" + location.host + "/live");

  let dom: Record<string, any>;
  const spktPreflightId = document
    .querySelector("meta[name=spkt-preflight-id]")
    ?.getAttribute("content");

  const spktCsrfToken = document
    .querySelector("meta[name=spkt-csrf-token]")
    ?.getAttribute("content");

  topbar.config({ barColors: { 0: "#29d" }, barThickness: 2 });
  topbar.show(500);

  socket.addEventListener("open", function (event) {
    socket.send(
      JSON.stringify(["join", { id: spktPreflightId, csrf: spktCsrfToken }])
    );
  });

  socket.addEventListener("message", function (event) {
    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "ok":
          topbar.hide();

          dom = parsed[1];

          break;

        case "update":
          dom = applyPatch(dom, parsed[1], parsed[2]) as Element;
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

      morphdom(document.documentElement, renderDom(dom), {
        onBeforeElUpdated: function (fromEl, toEl) {
          if (toEl.hasAttribute(constant.IgnoreUpdate)) return false;

          return true;
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
  });

  socket.addEventListener("close", function (event) {
    topbar.show();
  });

  // wire up event handlers
  initEventHandlers(socket);
});
