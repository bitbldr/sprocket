import { h, VNode, VNodeData, fragment } from "snabbdom";
import { constant } from "./constants";
import { isInteger, htmlDecode } from "./utils";
import { ClientHookProvider } from "./hooks";
import { EventHandlerProvider } from "./events";

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
      return renderElement(node, providers);
    case "component":
      return renderComponent(node, providers);
    case "fragment":
      return renderFragment(node, providers);
    default:
      throw new Error(`Unknown node type: ${node.type}`);
  }
}

function renderElement(element, providers: Providers): VNode {
  let { clientHookProvider, eventHandlerProvider } = providers;
  let data: VNodeData = { attrs: element.attrs };

  if (element.key) {
    data.key = element.key;
  }

  // TODO: figure out how to actually ignore updates with snabbdom
  if (element.ignore) {
    data.ignore = true;
  }

  if (hasClientHook(element.attrs)) {
    data.hook = {
      ...clientHookProvider(),
    };
  }

  // wire up event handlers
  const eventHandlers = wireEventHandlers(element.attrs, eventHandlerProvider);

  if (Object.keys(eventHandlers).length > 0) {
    data.on = eventHandlers;
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

function wireEventHandlers(
  attrs: Record<string, any>,
  eventHandlerProvider: EventHandlerProvider
) {
  return Object.keys(attrs)
    .filter((key) => key.startsWith(constant.EventAttrPrefix))
    .reduce((acc, key) => {
      const kind = key.replace(`${constant.EventAttrPrefix}-`, "");

      return {
        ...acc,
        [kind]: eventHandlerProvider({ kind, id: attrs[key] }),
      };
    }, {});
}

function hasClientHook(attrs: Record<string, any>) {
  const name = attrs && (attrs[`${constant.HookAttrPrefix}`] as string);
  const id = attrs && (attrs[`${constant.HookAttrPrefix}-id`] as string);

  if (id && name) {
    return true;
  }

  return false;
}
