export type EventIdentifier = {
  kind: string;
  id: string;
};

export type EventHandlerProvider = (event: EventIdentifier) => void;
