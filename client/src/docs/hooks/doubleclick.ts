import { ClientHookSpec } from "../../hooks";

export const doubleclick: ClientHookSpec = {
  mounted({ el, pushEvent }) {
    el.addEventListener("dblclick", () => {
      pushEvent("doubleclick", {});
    });
  },
};
