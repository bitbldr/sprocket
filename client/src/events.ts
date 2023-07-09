import { constStr } from "./constants";

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

      if (target.hasAttribute(`${constStr.EventAttrPrefix}-${kind}`)) {
        let id = target.attributes[`${constStr.EventAttrPrefix}-${kind}`].value;

        socket.send(JSON.stringify({ kind, id, value: (target as any).value }));
      }
    });
  });
}
