import { c } from "./constants";

const supportedEventKinds = ["click", "change", "input"];

export type EventHandler = {
  kind: string;
  handler: EventListener;
  el: Element;
};

export function attachEventHandlers(socket): EventHandler[] {
  return supportedEventKinds.reduce((acc, kind) => {
    const elements = Array.from(
      document.querySelectorAll(`[${c.EventAttrPrefix}-${kind}]`)
    )
      .filter((el) => !!el)
      .map((el) => {
        let id = el.attributes[`${c.EventAttrPrefix}-${kind}`].value;

        const handler = (e) => {
          socket.send(JSON.stringify({ kind, id }));
        };

        el.addEventListener(kind, handler);

        return {
          el,
          kind,
          handler,
        };
      });

    return [...acc, ...elements];
  }, [] as EventHandler[]);
}

export function detachEventHandlers(handlers: EventHandler[]) {
  handlers.forEach(({ el, kind, handler }) => {
    el.removeEventListener(kind, handler);
  });
}
