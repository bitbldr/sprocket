import { constant } from "./constants";

// map for browser events to listen for and the corresponding sprocket event types
// they potentially handle
const browserEventKinds = {
  click: ["click"],
  dblclick: ["dblclick"],
  change: ["change"],
  input: ["input"],
};

export type EventHandler = {
  kind: string;
  handler: EventListener;
  el: Element;
};

export function initEventHandlers(socket) {
  Object.keys(browserEventKinds).forEach((kind) => {
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
    const spktEvents = browserEventKinds[kind];
    let spktKind = spktEvents.find((spktEvent) => {
      return el.hasAttribute(`${constant.EventAttrPrefix}-${spktEvent}`);
    });

    if (spktKind) {
      let id = el.attributes[`${constant.EventAttrPrefix}-${spktKind}`].value;

      return { kind: spktKind, id, value };
    } else {
      return bubbleToNearestHandler(el.parentElement, kind, value);
    }
  }
}
