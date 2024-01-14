type PushEvent = (event: string, payload: any) => void;

type Hook = {
  el: Element;
  name: string;
  pushEvent: PushEvent;
  handleEvent: (event: string, handler: (payload: any) => any) => void;
};

export type ClientHook = {
  create?: (hook: Hook) => void;
  insert?: (hook: Hook) => void;
  update?: (hook: Hook) => void;
  destroy?: (hook: Hook) => void;
};
