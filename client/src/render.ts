import { isInteger } from "./utils";

// very naive and basic rendering algorithm
// TODO: rewrite to a more readable approach
export function renderDom(dom): string {
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

function renderComponent(component): string {
  let result = "";
  for (let i = 0; i < Object.keys(component).length - 1; i++) {
    result += renderDom(component[i]);
  }

  return result;
}

function renderElement(element): string {
  const openingTag =
    Object.keys(element.attrs).reduce((result, key) => {
      return result + ` ${key}="${element.attrs[key]}"`;
    }, `<${element.type}`) + ">";

  const children = Object.keys(element)
    .filter((key) => isInteger(key))
    .reduce((rendered, key) => rendered + renderDom(element[key]), "");

  const closingTag = "</" + element.type + ">";

  return openingTag + children + closingTag;
}
