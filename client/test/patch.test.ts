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
