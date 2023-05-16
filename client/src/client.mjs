import * as App from "app";

window.addEventListener("DOMContentLoaded", () => {
  App.main();

  const ws = new WebSocket("ws://localhost:3000/live");

  ws.onopen = () => {
    console.log("ws opened on browser");
    ws.send("hello world");
  };

  ws.onmessage = (message) => {
    console.log(`message received`, message.data);
  };
});
