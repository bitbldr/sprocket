// very naive and basic rendering algorithm
// TODO: rewrite to a more readable approach
export function renderDom(dom) {
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
