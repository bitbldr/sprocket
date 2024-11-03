import { h, VNode, VNodeData, fragment } from "snabbdom";
import { isInteger } from "./utils";
import { ClientHookProvider, HookIdentifier } from "./hooks";
import { EventHandlerProvider, EventIdentifier } from "./events";

export type Providers = {
  clientHookProvider: ClientHookProvider;
  eventHandlerProvider: EventHandlerProvider;
};

export function render(
  node: string | Record<string, any>,
  providers: Providers
): string | VNode {
  if (typeof node === "string") {
    return node;
  }

  switch (node.type) {
    case "element":
      return renderElement(node as Element, providers);
    case "component":
      return renderComponent(node, providers);
    case "fragment":
      return renderFragment(node, providers);
    case "custom":
      return renderCustom(node, providers);
    default:
      throw new Error(`Unknown node type: ${node.type}`);
  }
}

interface Element {
  type: "element";
  tag: string;
  attrs: Record<string, any>;
  events: EventIdentifier[];
  hooks: HookIdentifier[];
  key?: string;
  ignore?: boolean;
}

function renderElement(element: Element, providers: Providers): VNode {
  let { clientHookProvider, eventHandlerProvider } = providers;
  let data: VNodeData = { attrs: element.attrs };

  if (element.key) {
    data.key = element.key;
  }

  // TODO: figure out how to actually ignore updates with snabbdom
  if (element.ignore) {
    data.ignore = true;
  }

  if (element.hooks.length > 0) {
    data.hook = clientHookProvider(element.hooks);
  }

  // wire up event handlers
  if (element.events.length > 0) {
    data.on = eventHandlerProvider(element.tag, element.events);
  }

  return h(
    element.tag,
    data,
    Object.keys(element)
      .filter((key) => isInteger(key))
      .reduce((acc, key) => [...acc, render(element[key], providers)], [])
  );
}

function renderComponent(component, providers: Providers): string | VNode {
  return render(component["0"], providers);
}

function renderFragment(f, providers: Providers): VNode {
  return fragment(
    Object.keys(f)
      .filter((key) => isInteger(key))
      .reduce((acc, key) => [...acc, render(f[key], providers)], [])
  );
}

function renderCustom(custom, providers: Providers): VNode {
  switch (custom.kind) {
    case "raw":
      const { tag, attrs, innerHtml } = JSON.parse(custom.data);

      return h(tag, { attrs, innerHtml });

    default:
      throw new Error(`Unknown custom kind: ${custom.kind}`);
  }
}
