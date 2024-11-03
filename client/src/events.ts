import { On } from "snabbdom";
import { throttle, debounce } from "./utils";

export type EventIdentifier = {
  kind: string;
  id: string;
  throttleMs?: number;
  debounceMs?: number;
};

export type EventHandlerProvider = (
  tag: string,
  events: EventIdentifier[]
) => On;

export const initEventHandlerProvider =
  (
    socket: WebSocket,
    customEventEncoders: Record<string, any> = {}
  ): EventHandlerProvider =>
  (elementTag, events: EventIdentifier[]) =>
    events.reduce((acc, { kind, id, throttleMs, debounceMs }) => {
      let handler = (e) => {
        socket.send(
          JSON.stringify([
            "event",
            {
              id,
              kind,
              payload: payloadForEvent(
                e,
                elementTag,
                customEventEncoders[kind]
              ),
            },
          ])
        );
      };

      console.log("throttleMs, debounceMs", throttleMs, debounceMs, handler);

      const maybeDebounceOrThrottleHandler =
        (debounceMs && debounce(handler, debounceMs, false)) ||
        (throttleMs && throttle(handler, throttleMs));

      return {
        ...acc,
        [kind]: maybeDebounceOrThrottleHandler || handler,
      };
    }, {});

const payloadForEvent = (e: Event, elementTag, customEventEncoder) => {
  // If a custom event decoder is provided, use it
  if (customEventEncoder) {
    return customEventEncoder(e);
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
      ctrlKey: e.ctrlKey,
      shiftKey: e.shiftKey,
      altKey: e.altKey,
      metaKey: e.metaKey,
    };
  }

  if (e instanceof KeyboardEvent) {
    return {
      key: e.key,
      code: e.code,
      ctrlKey: e.ctrlKey,
      shiftKey: e.shiftKey,
      altKey: e.altKey,
      metaKey: e.metaKey,
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
