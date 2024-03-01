import { On } from "snabbdom";

export type EventIdentifier = {
  kind: string;
  id: string;
};

export type EventHandlerProvider = (events: EventIdentifier[]) => On;

export const initEventHandlerProvider =
  (socket: WebSocket): EventHandlerProvider =>
  (events: EventIdentifier[]) =>
    events.reduce((acc, { kind, id }) => {
      const handler = (e) => {
        socket.send(
          JSON.stringify(["event", { id, kind, value: e.target.value }])
        );
      };

      return {
        ...acc,
        [kind]: handler,
      };
    }, {});
