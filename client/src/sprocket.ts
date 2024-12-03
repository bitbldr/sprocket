import ReconnectingWebSocket, { ListenersMap } from "reconnecting-websocket";
import {
  init,
  attributesModule,
  eventListenersModule,
  VNode,
  toVNode,
} from "snabbdom";
import topbar from "topbar";
import { initEventHandlerProvider } from "./events";
import { initClientHookProvider, Hook } from "./hooks";
import { rawHtmlModule } from "./modules/rawHtml";
import { applyPatch } from "./patch";
import { render, Providers } from "./render";

export type ClientHook = {
  create?: (hook: Hook) => void;
  insert?: (hook: Hook) => void;
  update?: (hook: Hook) => void;
  destroy?: (hook: Hook) => void;
};

type Patcher = (
  oldVNode: VNode | Element | DocumentFragment,
  vnode: VNode
) => VNode;

type Opts = {
  csrfToken: string;
  targetEl?: Element;
  hooks?: Record<string, any>;
  initialProps?: Record<string, string>;
  customEventEncoders?: Record<string, any>;
};

export function connect(path: String, opts: Opts) {
  const csrfToken = opts.csrfToken || new Error("Missing CSRF token");
  const targetEl = opts.targetEl || document.documentElement;

  let ws_protocol = location.protocol === "https:" ? "wss:" : "ws:";
  const socket = new ReconnectingWebSocket(
    ws_protocol + "//" + location.host + path
  );
  const socketSend = (data: string) => socket.send(data);
  const socketAddEventListener = (
    event: keyof ListenersMap,
    listener: (event: any) => void
  ) => socket.addEventListener(event, listener);

  let oldVNode: VNode = toVNode(targetEl);
  let patched: Record<string, any>;

  const patcher = init(
    [attributesModule, eventListenersModule, rawHtmlModule],
    undefined,
    {
      experimental: {
        fragments: true,
      },
    }
  );

  let providers: Providers;

  topbar.config({ barColors: { 0: "#29d" }, barThickness: 2 });
  topbar.show(500);

  socketAddEventListener("open", function (event) {
    console.log("open");

    providers = {
      clientHookProvider: initClientHookProvider(
        socketSend,
        socketAddEventListener,
        opts.hooks
      ),
      eventHandlerProvider: initEventHandlerProvider(
        socketSend,
        opts.customEventEncoders
      ),
    };

    socketSend(
      JSON.stringify([
        "join",
        { csrf: csrfToken, initialProps: opts.initialProps },
      ])
    );
  });

  socketAddEventListener("message", function (event) {
    let parsed = JSON.parse(event.data);

    if (Array.isArray(parsed)) {
      switch (parsed[0]) {
        case "ok":
          topbar.hide();

          patched = parsed[1];
          oldVNode = update(patcher, oldVNode, patched, providers);

          break;

        case "update":
          patched = applyPatch(patched, parsed[1], parsed[2]) as Element;

          oldVNode = update(patcher, oldVNode, patched, providers);

          break;

        case "error":
          const { code, msg } = parsed[1];
          console.error(`Error ${code}: ${msg}`);

          break;
      }
    }
  });

  socketAddEventListener("close", function (_event) {
    topbar.show();
  });
}

// update the target DOM element using a given JSON DOM
function update(
  patcher: Patcher,
  oldVNode: VNode,
  patched: Record<string, any>,
  providers: Providers
) {
  const rendered = render(patched, providers) as VNode;

  return patcher(oldVNode, rendered);
}
