import { h, VNode, VNodeData, fragment } from "snabbdom";
import { constant } from "./constants";
import { isInteger, htmlDecode } from "./utils";
import { ClientHookProvider } from "./hooks";

export function render(
  node: string | Record<string, any>,
  clientHookProvider: ClientHookProvider
): string | VNode {
  if (typeof node === "string") {
    return htmlDecode(node);
  }

  switch (node.type) {
    case "element":
      return renderElement(node, clientHookProvider);
    case "component":
      return renderComponent(node, clientHookProvider);
    case "fragment":
      return renderFragment(node, clientHookProvider);
    default:
      throw new Error(`Unknown node type: ${node.type}`);
  }
}

function renderElement(element, clientHookProvider: ClientHookProvider): VNode {
  let data: VNodeData = { attrs: element.attrs };

  if (element.key) {
    data.key = element.key;
  }

  // TODO: figure out how to actually ignore updates with snabbdom
  if (element.ignore) {
    data.ignore = true;
  }

  // if (element.events) {
  //   data.on = element.events;
  // }

  if (hasClientHook(element.attrs)) {
    data.hook = {
      ...clientHookProvider(),
    };
  }

  return h(
    element.tag,
    data,
    Object.keys(element)
      .filter((key) => isInteger(key))
      .reduce(
        (acc, key) => [...acc, render(element[key], clientHookProvider)],
        []
      )
  );
}

function renderComponent(
  component,
  clientHookProvider: ClientHookProvider
): string | VNode {
  return render(component.el, clientHookProvider);
}

function renderFragment(f, clientHookProvider: ClientHookProvider): VNode {
  // ideally, fragments would also allow a key to help inform the patcher about
  // the position of the fragment in the DOM, but snabbdom doesn't support that
  // yet, so we have to leave it up to snabbdom to figure out the position for now

  return fragment(
    Object.keys(f)
      .filter((key) => isInteger(key))
      .reduce((acc, key) => [...acc, render(f[key], clientHookProvider)], [])
  );
}

function hasClientHook(attrs: Record<string, any>) {
  const name = attrs && (attrs[`${constant.HookAttrPrefix}`] as string);
  const id = attrs && (attrs[`${constant.HookAttrPrefix}-id`] as string);

  if (id && name) {
    return true;
  }

  return false;
}
