import { doubleclick } from "./hooks/doubleclick";
import { connect } from "../sprocket";

const hooks = {
  DoubleClick: doubleclick,
};

window.addEventListener("DOMContentLoaded", () => {
  const preflightId = document
    .querySelector("meta[name=spkt-preflight-id]")
    ?.getAttribute("content");

  const csrfToken = document
    .querySelector("meta[name=spkt-csrf-token]")
    ?.getAttribute("content");

  if (preflightId && csrfToken) {
    connect("/live", {
      hooks,
      dom: document.documentElement,
      preflightId,
      csrfToken,
    });
  } else {
    console.error("Missing preflight ID or CSRF token");
  }
});
