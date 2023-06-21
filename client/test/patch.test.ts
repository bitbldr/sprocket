import { applyPatch, Patch } from "../src/patch";

test("applyPatch updates attributes", () => {
  const original = {
    tag: "div",
    attrs: {},
    0: {
      tag: "h1",
      attrs: {},
      0: "Hello",
    },
    1: {
      tag: "p",
      attrs: {},
      0: "World",
    },
  };

  const patch: Patch = [
    1,
    {
      class: "foo",
    },
    {
      "0": [1, { class: "bar" }, null],
      "1": [1, { class: "baz" }, null],
    },
  ];

  const dom = applyPatch(original, patch);

  expect(dom).toEqual({
    tag: "div",
    attrs: {
      class: "foo",
    },
    0: {
      tag: "h1",
      attrs: {
        class: "bar",
      },
      0: "Hello",
    },
    1: {
      tag: "p",
      attrs: {
        class: "baz",
      },
      0: "World",
    },
  });
});

test("applyPatch replaces element", () => {
  const original = {
    tag: "div",
    attrs: {
      class: "foo",
    },
    0: {
      tag: "h1",
      attrs: {},
      0: "Hello",
    },
    1: {
      tag: "p",
      attrs: {},
      0: "World",
    },
  };

  const patch: Patch = [
    1,
    null,
    {
      "0": [
        2,
        {
          tag: "p",
          attrs: {},
          0: "Hello Changed",
        },
      ],
    },
  ];

  const dom = applyPatch(original, patch);

  expect(dom).toEqual({
    tag: "div",
    attrs: {
      class: "foo",
    },
    0: {
      tag: "p",
      attrs: {},
      0: "Hello Changed",
    },
    1: {
      tag: "p",
      attrs: {},
      0: "World",
    },
  });
});

test("applyPatch with root component", () => {
  const original = {
    type: "component",
    "0": {
      "0": {
        "0": {
          type: "link",
          attrs: {
            rel: "stylesheet",
            href: "/app.css",
          },
        },
        type: "head",
        attrs: {},
      },
      "1": {
        "0": {
          "0": {
            "0": "Hello World!",
            type: "h1",
            attrs: {},
          },
          "1": {
            "0": "The current time is: ",
            "1": "1687304620",
            type: "component",
          },
          type: "div",
          attrs: {},
        },
        "1": {
          "0": "A test component",
          "1": {
            "0": {
              "0": {
                "0": "-",
                type: "button",
                attrs: {
                  class: "p-1 px-2 border rounded-l bg-gray-100",
                  "spkt-event": "click=583a18dc-eaf0-4eca-be72-854e8df8af1a",
                },
              },
              "1": {
                "0": "0",
                type: "span",
                attrs: {
                  class:
                    "p-1 px-2 w-10 border-t border-b align-center text-center",
                },
              },
              "2": {
                "0": "+",
                type: "button",
                attrs: {
                  class: "p-1 px-2 border rounded-r bg-gray-100",
                  "spkt-event": "click=6941a44e-a840-4f0d-a547-c2f0172a86a1",
                },
              },
              type: "div",
              attrs: {
                class: "flex flex-row m-4",
              },
            },
            type: "component",
          },
          type: "div",
          attrs: {},
        },
        "2": {
          type: "script",
          attrs: {
            src: "/client.js",
          },
        },
        type: "body",
        attrs: {
          class: "bg-white dark:bg-gray-900 dark:text-white",
        },
      },
      type: "html",
      attrs: {
        lang: "en",
      },
    },
  };

  const patch: Patch = [
    1,
    null,
    {
      "0": [
        1,
        null,
        {
          "1": [
            1,
            null,
            {
              "0": [
                1,
                null,
                {
                  "1": [
                    1,
                    null,
                    {
                      "1": [5, "1687304621"],
                    },
                  ],
                },
              ],
              "1": [
                1,
                null,
                {
                  "1": [
                    1,
                    null,
                    {
                      "0": [
                        1,
                        null,
                        {
                          "0": [
                            1,
                            {
                              class: "p-1 px-2 border rounded-l bg-gray-100",
                              "spkt-event":
                                "click=97b92259-b114-47ab-9172-9a095742bfce",
                            },
                            null,
                          ],
                          "2": [
                            1,
                            {
                              class: "p-1 px-2 border rounded-r bg-gray-100",
                              "spkt-event":
                                "click=0953e1a6-b199-44e6-a500-b803a2fc9558",
                            },
                            null,
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  ] as any;

  const dom = applyPatch(original, patch);

  expect(dom).toEqual({
    type: "component",
    "0": {
      "0": {
        "0": {
          type: "link",
          attrs: {
            rel: "stylesheet",
            href: "/app.css",
          },
        },
        type: "head",
        attrs: {},
      },
      "1": {
        "0": {
          "0": {
            "0": "Hello World!",
            type: "h1",
            attrs: {},
          },
          "1": {
            "0": "The current time is: ",
            "1": "1687304621",
            type: "component",
          },
          type: "div",
          attrs: {},
        },
        "1": {
          "0": "A test component",
          "1": {
            "0": {
              "0": {
                "0": "-",
                type: "button",
                attrs: {
                  class: "p-1 px-2 border rounded-l bg-gray-100",
                  "spkt-event": "click=97b92259-b114-47ab-9172-9a095742bfce",
                },
              },
              "1": {
                "0": "0",
                type: "span",
                attrs: {
                  class:
                    "p-1 px-2 w-10 border-t border-b align-center text-center",
                },
              },
              "2": {
                "0": "+",
                type: "button",
                attrs: {
                  class: "p-1 px-2 border rounded-r bg-gray-100",
                  "spkt-event": "click=0953e1a6-b199-44e6-a500-b803a2fc9558",
                },
              },
              type: "div",
              attrs: {
                class: "flex flex-row m-4",
              },
            },
            type: "component",
          },
          type: "div",
          attrs: {},
        },
        "2": {
          type: "script",
          attrs: {
            src: "/client.js",
          },
        },
        type: "body",
        attrs: {
          class: "bg-white dark:bg-gray-900 dark:text-white",
        },
      },
      type: "html",
      attrs: {
        lang: "en",
      },
    },
  });
});
