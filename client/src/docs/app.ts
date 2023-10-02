import { doubleclick } from "./hooks/doubleclick";
import { connect } from "../sprocket";

const hooks = {
  DoubleClick: doubleclick,
};

window.addEventListener("DOMContentLoaded", () => {
  const csrfToken = document
    .querySelector("meta[name=csrf-token]")
    ?.getAttribute("content");

  if (csrfToken) {
    console.log(window.location.pathname.split("/"));
    let livePath =
      window.location.pathname === "/"
        ? "/live"
        : window.location.pathname.split("/").concat("live").join("/");

    connect(livePath, {
      csrfToken,
      // targetEl: document.querySelector("#app") as Element,
      hooks,
    });
  } else {
    console.error("Missing CSRF token");
  }
});
