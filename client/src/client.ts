import morphdom from "morphdom";
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
          dom = parsed[1];
          break;

        case "update":
          dom = applyPatch(dom, parsed[1]) as Element;
          break;
      }

      morphdom(document.documentElement, renderDom(dom), {
        onBeforeElUpdated: function (fromEl, toEl) {
          if (toEl.hasAttribute(constant.IgnoreUpdate)) return false;

          return true;
        },
      });
    }
  });

  // wire up event handlers
  initEventHandlers(socket);
});
