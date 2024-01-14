import { Module } from "snabbdom";
import ReconnectingWebSocket from "reconnecting-websocket";

export const ignoreUpdatesModule = (socket: ReconnectingWebSocket): Module => {
  let ignoredVNodes;

  return {
    create: function (oldVnode, vnode) {
      // invoked whenever a new virtual node is created
      console.log("create", vnode);

      if (vnode.data.ignore) {
        // ignoredVNodes[vnode] = vnode;
      }
    },
    update: function (oldVnode, vnode) {
      // invoked whenever a virtual node is updated
      console.log("update", vnode);
    },
  };
};
