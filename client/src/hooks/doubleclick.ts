export type PushEvent = (event: string, payload: any) => void;
export type ClientHook = {
  mounted?: (params: { el: Element; pushEvent: PushEvent }) => void;
  // beforeUpdate?: (params: { el: Element }) => void;
  // updated?: (params: { el: Element }) => void;
  // destroyed?: (params: { el: Element }) => void;
  // connected?: (params: { el: Element }) => void;
  // disconnected?: (params: { el: Element }) => void;
};

export const doubleclick: ClientHook = {
  mounted({ el, pushEvent }) {
    console.log("doubleclick mounted", el);

    el.addEventListener("dblclick", () => {
      pushEvent("doubleclick", {});
    });
  },
};
