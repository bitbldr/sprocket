// import * as App from "app";
import morphdom from "morphdom";

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
      }
    }
  });
});
