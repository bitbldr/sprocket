import morphdom from "morphdom";
import { renderDom } from "./render";
import { applyPatch } from "./patch";
import { attachEventHandlers } from "./events";

window.addEventListener("DOMContentLoaded", () => {
  const socket = new WebSocket("ws://localhost:3000/live");

  let dom: Record<string, any>;

  socket.addEventListener("open", function (event) {
    console.log("ws opened on browser");
    socket.send(JSON.stringify(["join"]));
  });
  socket.addEventListener("message", function (event) {
    console.log("Message from server ", event.data);

    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      const body = document.querySelector("body") as Node;

      switch (parsed[0]) {
        case "init":
          console.log("initializing body with: ", parsed[1]);

          dom = parsed[1];
          morphdom(body, renderDom(dom));

          break;

        case "update":
          console.log("updating body with: ", parsed[1]);

          dom = applyPatch(dom, parsed[1]) as Element;

          console.log("dom: ", dom);

          let rendered = renderDom(dom);

          console.log("rendered: ", rendered);

          morphdom(body, rendered);

          attachEventHandlers(socket);

          break;
      }
    }
  });

  // wire up event handlers
  attachEventHandlers(socket);
});
