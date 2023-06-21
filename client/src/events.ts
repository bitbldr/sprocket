export function attachEventHandlers(socket) {
  document.querySelectorAll("[live-event]").forEach((el) => {
    let [event, id] = el.attributes["live-event"].value.split("=");

    el.addEventListener(event, (e) => {
      socket.send(JSON.stringify({ event, id }));
    });
  });
}
