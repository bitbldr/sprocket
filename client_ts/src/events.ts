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
    customEventEncoders: Record<string, any> = {},
    sendEvent: (elementId: string, kind: string, payload: any) => void
  ): EventHandlerProvider =>
  (elementTag, events: EventIdentifier[]) =>
    events.reduce((acc, { kind, id }) => {
      const handler = (e) =>
        sendEvent(
          id,
          kind,
          payloadForEvent(e, elementTag, customEventEncoders[kind])
        );

      return {
        ...acc,
        [kind]: handler,
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

  if (e.type === "change" && e.target instanceof HTMLInputElement) {
    // If the event is a change event attached to a form, we want to send all the form data
    if (elementTag === "form") {
      return {
        formData: buildFormData(e.target.form),
      };
    }

    // Otherwise, we just send the value of the target input
    return {
      target: {
        value: e.target.value,
      },
    };
  }

  return null;
};

const buildFormData = (form: HTMLFormElement) => {
  const formData = {};

  new FormData(form).forEach((value, key) => (formData[key] = value));

  return formData;
};
