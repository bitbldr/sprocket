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

      const handler = bubbleToNearestHandler(
        target,
        kind,
        (target as any).value
      );

      if (handler) {
        socket.send(JSON.stringify(["event", handler]));
      }
    });
  });
}

function bubbleToNearestHandler(el: Element | null, kind: string, value: any) {
  if (el) {
    if (el.hasAttribute(`${constant.EventAttrPrefix}-${kind}`)) {
      let id = el.attributes[`${constant.EventAttrPrefix}-${kind}`].value;
      return { kind, id, value };
    } else {
      return bubbleToNearestHandler(el.parentElement, kind, value);
    }
  }
}
