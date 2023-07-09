import { constant } from "./constants";

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

      if (target.hasAttribute(`${constant.EventAttrPrefix}-${kind}`)) {
        let id = target.attributes[`${constant.EventAttrPrefix}-${kind}`].value;

        socket.send(JSON.stringify({ kind, id, value: (target as any).value }));
      }
    });
  });
}
