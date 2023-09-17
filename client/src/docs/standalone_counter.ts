import { connect } from "../sprocket";

window.addEventListener("DOMContentLoaded", () => {
  const csrfToken = document
    .querySelector("meta[name=csrf-token]")
    ?.getAttribute("content");

  if (csrfToken) {
    connect("/counter/live", {
      csrfToken,
      targetEl: document.getElementById("counter") as Element,
    });
  } else {
    console.error("Missing CSRF token");
  }
});
