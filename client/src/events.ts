import { c } from "./constants";

const supportedEventKinds = ["click", "change", "input"];

export type EventHandler = {
  kind: string;
  handler: EventListener;
  el: Element;
};

export function initEventHandlers(socket) {
  supportedEventKinds.forEach((kind) => {
    window.addEventListener(kind, (e) => {
      let target = e.target as Element;

      if (target.hasAttribute(`${c.EventAttrPrefix}-${kind}`)) {
        let id = target.attributes[`${c.EventAttrPrefix}-${kind}`].value;

        socket.send(JSON.stringify({ kind, id }));
      }
    });
  });
}
