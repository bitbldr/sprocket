import { h, VNode, VNodeData, fragment } from "snabbdom";
import { isInteger, htmlDecode } from "./utils";

export function render(node: string | Record<string, any>): string | VNode {
  if (typeof node === "string") {
    return htmlDecode(node);
  }

  switch (node.type) {
    case "element":
      return renderElement(node);
    case "component":
      return renderComponent(node);
    case "fragment":
      return renderFragment(node);
    default:
      throw new Error(`Unknown node type: ${node.type}`);
  }
}

function renderElement(element): VNode {
  let data: VNodeData = { attrs: element.attrs };

  if (element.key) {
    data.key = element.key;
  }

  return h(
    element.tag,
    data,
    Object.keys(element)
      .filter((key) => isInteger(key))
      .reduce((acc, key) => [...acc, render(element[key])], [])
  );
}

function renderComponent(component): string | VNode {
  return render(component.el);
}

function renderFragment(f): VNode {
  // ideally, fragments would also allow a key to help inform the patcher about
  // the position of the fragment in the DOM, but snabbdom doesn't support that
  // yet, so we have to leave it up to snabbdom to figure out the position for now
  return fragment(f.children.map((child) => render(child)));
}
