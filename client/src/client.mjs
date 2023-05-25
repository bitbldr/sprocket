// import * as App from "app";
import morphdom from "morphdom";

function attachEventHandlers(socket) {
  document.querySelectorAll("[data-event]").forEach((el) => {
    let [event, id] = el.attributes["data-event"].value.split("=");

    el.addEventListener(event, (e) => {
      socket.send(JSON.stringify({ event, id }));
    });
  });
}

window.addEventListener("DOMContentLoaded", () => {
  // App.main();

  const socket = new WebSocket("ws://localhost:3000/live");

  socket.addEventListener("open", function (event) {
    console.log("ws opened on browser");
    socket.send(["join"]);
  });
  socket.addEventListener("message", function (event) {
    console.log("Message from server ", event.data);

    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "update":
          console.log("updating body with: ", parsed[1]);
          let body = document.querySelector("body");
          morphdom(body, parsed[1]);

          attachEventHandlers(socket);
      }
    }
  });

  // wire up event handlers
  attachEventHandlers(socket);
});
