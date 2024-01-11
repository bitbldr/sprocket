import { h, VNode, fragment } from "snabbdom";
import { isInteger, htmlDecode } from "./utils";

// Renders a node as a vnode
export function render(node: string | Record<string, any>): VNode | string {
  if (typeof node === "string") {
    return htmlDecode(node);
  }

  switch (node.type) {
    case "component":
      return renderComponent(node);
    default:
      return renderElement(node);
  }
}

// Renders a component as a fragment of its children
function renderComponent(component): VNode {
  return fragment(
    Object.keys(component).reduce((acc, _key, i) => {
      return component[i] ? [...acc, render(component[i])] : acc;
    }, [])
  );
}

// Renders an element as a vnode
function renderElement(element): VNode {
  return h(
    element.type,
    { attrs: element.attrs },
    Object.keys(element)
      .filter((key) => isInteger(key))
      .reduce((acc, key) => [...acc, render(element[key])], [])
  );
}
