import { On } from "snabbdom";

export type EventIdentifier = {
  kind: string;
  id: string;
};

export type EventHandlerProvider = (
  tag: string,
  events: EventIdentifier[]
) => On;

export const initEventHandlerProvider =
  (socket: WebSocket): EventHandlerProvider =>
  (el, events: EventIdentifier[]) =>
    events.reduce((acc, { kind, id }) => {
      const handler = (e) => {
        socket.send(
          JSON.stringify(["event", { id, kind, value: valueForEvent(e) }])
        );
      };

      return {
        ...acc,
        [kind]: handler,
      };
    }, {});

const valueForEvent = (e) => {
  if (e instanceof InputEvent || e instanceof PointerEvent) {
    return {
      target: {
        value: (e.target as any).value,
      },
    };
  }

  if (e instanceof MouseEvent) {
    return {
      clientX: e.clientX,
      clientY: e.clientY,
    };
  }

  if (e instanceof KeyboardEvent) {
    return {
      key: e.key,
    };
  }

  if (e instanceof SubmitEvent) {
    // prevent the default form submission and page reload
    e.preventDefault();

    const formData = {};
    new FormData(e.target as HTMLFormElement).forEach(
      (value, key) => (formData[key] = value)
    );

    return {
      formData: formData,
    };
  }

  return null;
};
