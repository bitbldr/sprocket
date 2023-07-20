import { constant } from "./constants";

// map for browser events to listen for and the corresponding sprocket event types
// they potentially handle
const browserEventKinds = {
  click: ["click", "doubleclick"],
  change: ["change"],
  input: ["input"],
};

const DOUBLE_CLICK_THRESHOLD = 500;
let pendingDoubleClicks: string[] = [];

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
        if (handler.kind === "doubleclick") {
          if (pendingDoubleClicks.find((id) => id === handler.id)) {
            // double click detected
            socket.send(JSON.stringify(["event", handler]));
            pendingDoubleClicks = pendingDoubleClicks.filter(
              (id) => id !== handler.id
            );
          } else {
            // track this as a potential first click in a double click sequence
            pendingDoubleClicks.push(handler.id);

            // clear the pending doubleclick event after a threshold
            setTimeout(() => {
              pendingDoubleClicks = pendingDoubleClicks.filter(
                (id) => id !== handler.id
              );
            }, DOUBLE_CLICK_THRESHOLD);
          }
        } else {
          socket.send(JSON.stringify(["event", handler]));
        }
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
