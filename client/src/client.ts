import morphdom from "morphdom";
import { renderDom } from "./render";
import { applyPatch } from "./patch";
import { initEventHandlers } from "./events";

window.addEventListener("DOMContentLoaded", () => {
  const socket = new WebSocket("ws://localhost:3000/live");

  let dom: Record<string, any>;

  socket.addEventListener("open", function (event) {
    socket.send(JSON.stringify(["join"]));
  });
  socket.addEventListener("message", function (event) {
    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "init":
          dom = parsed[1];
          morphdom(document.documentElement, renderDom(dom));

          break;

        case "update":
          dom = applyPatch(dom, parsed[1]) as Element;

          let rendered = renderDom(dom);

          morphdom(document.documentElement, rendered);

          break;
      }
    }
  });

  // wire up event handlers
  initEventHandlers(socket);
});
