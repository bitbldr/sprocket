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
  (
    socket: WebSocket,
    customEventDecoders: Record<string, any> = {}
  ): EventHandlerProvider =>
  (elementTag, events: EventIdentifier[]) =>
    events.reduce((acc, { kind, id }) => {
      const handler = (e) => {
        socket.send(
          JSON.stringify([
            "event",
            {
              id,
              kind,
              value: valueForEvent(e, elementTag, customEventDecoders[kind]),
            },
          ])
        );
      };

      return {
        ...acc,
        [kind]: handler,
      };
    }, {});

const valueForEvent = (e: Event, elementTag, customEventDecoder) => {
  // If a custom event decoder is provided, use it
  if (customEventDecoder) {
    return customEventDecoder(e);
  }

  // Otherwise, use the default event decoder based on the event type
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

  // If the event is a submit event, we want to prevent the default form
  // submission and send the form data instead
  if (e instanceof SubmitEvent) {
    // prevent the default form submission and page reload
    e.preventDefault();

    return {
      formData: buildFormData(e.target as HTMLFormElement),
    };
  }

  // If the event is a change event on a form, we want to send the form data
  if (elementTag === "form" && e.type === "change") {
    const inputEl = e.target as HTMLInputElement;

    if (!inputEl.form) {
      throw new Error(
        "form change event requires the input to be inside a form"
      );
    }

    return {
      formData: buildFormData(inputEl.form),
    };
  }

  return null;
};

const buildFormData = (form: HTMLFormElement) => {
  const formData = {};

  new FormData(form).forEach((value, key) => (formData[key] = value));

  return formData;
};
