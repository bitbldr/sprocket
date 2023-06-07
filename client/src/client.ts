// import * as App from "app";
import morphdom from "morphdom";

function attachEventHandlers(socket) {
  document.querySelectorAll("[live-event]").forEach((el) => {
    let [event, id] = el.attributes["live-event"].value.split("=");

    el.addEventListener(event, (e) => {
      socket.send(JSON.stringify({ event, id }));
    });
  });
}

window.addEventListener("DOMContentLoaded", () => {
  // App.main();

  const socket = new WebSocket("ws://localhost:3000/live");

  let dom: Record<string, any> | null = null;

  socket.addEventListener("open", function (event) {
    console.log("ws opened on browser");
    socket.send(JSON.stringify(["join"]));
  });
  socket.addEventListener("message", function (event) {
    console.log("Message from server ", event.data);

    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "update":
          console.log("updating body with: ", parsed[1]);

          dom = applyDiff(dom, parsed[1]);
          // dom = parsed[1];
          // if (dom === null) {
          //   dom = parsed[1];
          // } else {
          //   dom = patchDom(dom, parsed[1]);
          // }

          console.log("dom: ", dom);

          let rendered = renderDom(dom);

          console.log("rendered: ", rendered);

          let body = document.querySelector("body") as Node;
          morphdom(body, rendered);

          attachEventHandlers(socket);
      }
    }
  });

  // wire up event handlers
  attachEventHandlers(socket);
});

// very naive and basic rendering algorithm
// TODO: rewrite to a more readable approach
function renderDom(dom) {
  if (typeof dom === "string") {
    return dom;
  }

  switch (dom.type) {
    case "component":
      return renderComponent(dom);
    default:
      return renderElement(dom);
  }
}

function renderComponent(component) {
  let result = "";
  for (let i = 0; i < Object.keys(component).length - 1; i++) {
    result += renderDom(component[i]);
  }

  return result;
}

function renderElement(element) {
  let result = "";

  result += `<${element.type}`;
  result += Object.keys(element.attrs).map((key) => {
    return ` ${key}="${element.attrs[key]}"`;
  });
  result += ">";

  for (let i = 0; i < Object.keys(element).length - 2; i++) {
    result += renderDom(element[i]);
  }

  result += "</" + element.type + ">";

  return result;
}

function applyDiff(
  original: Record<string, any> | null,
  diff: Record<string, any>
): Record<string, any> {
  if (original === null) {
    return diff;
  }

  if (
    typeof original === "object" &&
    typeof diff === "object" &&
    original !== null &&
    diff !== null
  ) {
    for (const [key, value] of Object.entries(diff)) {
      if (key in original) {
        if (
          typeof value === "object" &&
          typeof original[key] === "object" &&
          original[key] !== null
        ) {
          applyDiff(original[key], value);
        } else if (value === null) {
          delete original[key];
        } else {
          original[key] = value;
        }
      } else {
        original[key] = value;
      }
    }
  } else if (Array.isArray(original) && Array.isArray(diff)) {
    for (let i = 0; i < diff.length; i++) {
      if (i < original.length) {
        if (
          typeof diff[i] === "object" &&
          typeof original[i] === "object" &&
          original[i] !== null
        ) {
          applyDiff(original[i], diff[i]);
        } else if (diff[i] === null) {
          original.splice(i, 1);
          i--;
        } else {
          original[i] = diff[i];
        }
      } else {
        original.push(diff[i]);
      }
    }
  }

  return original;
}
