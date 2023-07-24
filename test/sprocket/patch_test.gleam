import gleam/json
import gleam/string
import gleeunit/should
import gleam/dynamic
import gleam/option.{None, Some}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedText,
}
import sprocket/internal/patch.{
  Change, Insert, Move, NoOp, Remove, Replace, Update, op_code,
}
import sprocket/internal/utils/ordered_map

// gleeunit test functions end in `_test`
pub fn text_change_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              1,
              Update(
                attrs: None,
                children: Some([#(0, Change(text: "Changed"))]),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn first_fc_without_children_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Insert(el: RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        )),
      ),
    ]),
  ))
}

pub fn add_child_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Great")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Big")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(1, Update(attrs: None, children: Some([#(0, Change("Great"))]))),
            #(
              2,
              Insert(RenderedElement(
                tag: "p",
                key: None,
                attrs: [],
                children: [RenderedText("Big")],
              )),
            ),
            #(
              3,
              Insert(RenderedElement(
                tag: "p",
                key: None,
                attrs: [],
                children: [RenderedText("World")],
              )),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn add_move_child_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("great"),
              attrs: [],
              children: [RenderedText("Great")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("big"),
              attrs: [],
              children: [RenderedText("Big")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              1,
              Replace(RenderedElement(
                tag: "p",
                key: Some("great"),
                attrs: [],
                children: [RenderedText("Great")],
              )),
            ),
            #(
              2,
              Insert(RenderedElement(
                tag: "p",
                key: Some("big"),
                attrs: [],
                children: [RenderedText("Big")],
              )),
            ),
            #(3, Move(from: 1, patch: NoOp)),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn add_move_update_child_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [RenderedAttribute("class", "round")],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("great"),
              attrs: [],
              children: [RenderedText("Great")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("big"),
              attrs: [],
              children: [RenderedText("Big")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [
                RenderedAttribute("class", "round"),
                RenderedAttribute("class", "blue"),
              ],
              children: [RenderedText("Blue"), RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              1,
              Replace(RenderedElement(
                tag: "p",
                key: Some("great"),
                attrs: [],
                children: [RenderedText("Great")],
              )),
            ),
            #(
              2,
              Insert(RenderedElement(
                tag: "p",
                key: Some("big"),
                attrs: [],
                children: [RenderedText("Big")],
              )),
            ),
            #(
              3,
              Move(
                from: 1,
                patch: Update(
                  attrs: Some([
                    RenderedAttribute("class", "round"),
                    RenderedAttribute("class", "blue"),
                  ]),
                  children: Some([
                    #(0, Change("Blue")),
                    #(1, Insert(RenderedText("World"))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn add_move_replace_child_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("great"),
              attrs: [],
              children: [RenderedText("Great")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("big"),
              attrs: [],
              children: [RenderedText("Big")],
            ),
            RenderedElement(
              tag: "div",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("Blue"), RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              1,
              Replace(RenderedElement(
                tag: "p",
                key: Some("great"),
                attrs: [],
                children: [RenderedText("Great")],
              )),
            ),
            #(
              2,
              Insert(RenderedElement(
                tag: "p",
                key: Some("big"),
                attrs: [],
                children: [RenderedText("Big")],
              )),
            ),
            #(
              3,
              Move(
                from: 1,
                patch: Replace(RenderedElement(
                  tag: "div",
                  key: Some("world"),
                  attrs: [],
                  children: [RenderedText("Blue"), RenderedText("World")],
                )),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn remove_middle_child_in_list_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("three"),
              attrs: [],
              children: [RenderedText("Three")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four"), RenderedText("and a half")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              2,
              Move(
                from: 3,
                patch: Update(
                  attrs: None,
                  children: Some([#(1, Insert(RenderedText("and a half")))]),
                ),
              ),
            ),
            #(3, Move(from: 4, patch: NoOp)),
            #(4, Remove),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn restore_full_list_from_partial_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("three"),
              attrs: [],
              children: [RenderedText("Three")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              2,
              Replace(RenderedElement(
                tag: "li",
                key: Some("three"),
                attrs: [],
                children: [RenderedText("Three")],
              )),
            ),
            #(3, Move(from: 2, patch: NoOp)),
            #(4, Move(from: 3, patch: NoOp)),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn remove_first_couple_items_in_list_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("three"),
              attrs: [],
              children: [RenderedText("Three")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [
                RenderedText("Five"),
                RenderedComponent(
                  fc,
                  None,
                  props,
                  ordered_map.new(),
                  [RenderedText("and some change")],
                ),
              ],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              0,
              Replace(RenderedElement(
                tag: "li",
                key: Some("three"),
                attrs: [],
                children: [RenderedText("Three")],
              )),
            ),
            #(1, Move(from: 2, patch: NoOp)),
            #(
              2,
              Move(
                from: 3,
                patch: Update(
                  attrs: None,
                  children: Some([
                    #(
                      1,
                      Insert(RenderedComponent(
                        fc,
                        None,
                        props,
                        ordered_map.new(),
                        [RenderedText("and some change")],
                      )),
                    ),
                  ]),
                ),
              ),
            ),
            #(3, Remove),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn noop_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(NoOp)
}

pub fn shift_list_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "ul",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "li",
              key: Some("uno"),
              attrs: [],
              children: [RenderedText("Uno")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("dos"),
              attrs: [],
              children: [RenderedText("Dos")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("tres"),
              attrs: [],
              children: [RenderedText("Tres")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [RenderedText("One")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("two"),
              attrs: [],
              children: [RenderedText("Two")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("four"),
              attrs: [],
              children: [RenderedText("Four")],
            ),
            RenderedElement(
              tag: "li",
              key: Some("five"),
              attrs: [],
              children: [RenderedText("Five")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              0,
              Replace(RenderedElement(
                tag: "li",
                key: Some("uno"),
                attrs: [],
                children: [RenderedText("Uno")],
              )),
            ),
            #(
              1,
              Replace(RenderedElement(
                tag: "li",
                key: Some("dos"),
                attrs: [],
                children: [RenderedText("Dos")],
              )),
            ),
            #(
              2,
              Replace(RenderedElement(
                tag: "li",
                key: Some("tres"),
                attrs: [],
                children: [RenderedText("Tres")],
              )),
            ),
            #(3, Move(from: 0, patch: NoOp)),
            #(4, Move(from: 1, patch: NoOp)),
            #(5, Move(from: 2, patch: NoOp)),
            #(6, Move(from: 3, patch: NoOp)),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn attribute_change_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [RenderedAttribute("class", "bold")],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [RenderedAttribute("class", "italic")],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [
                RenderedAttribute("class", "bold"),
                RenderedAttribute("class", "italic"),
              ],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              0,
              Update(
                attrs: Some([
                  RenderedAttribute("class", "bold"),
                  RenderedAttribute("class", "italic"),
                ]),
                children: None,
              ),
            ),
            #(
              1,
              Update(
                attrs: Some([]),
                children: Some([#(0, Change(text: "Changed"))]),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn fc_change_test() {
  let props = dynamic.from([])

  let fc1 = fn(ctx, _) { #(ctx, []) }

  let first =
    RenderedComponent(
      fc: fc1,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Original Functional Component")],
            ),
          ],
        ),
      ],
    )

  let fc2 = fn(ctx, _) { #(ctx, []) }

  let second =
    RenderedComponent(
      fc: fc2,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Functional Component")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Replace(RenderedComponent(
    fc: fc2,
    key: None,
    props: props,
    hooks: ordered_map.new(),
    children: [
      RenderedElement(
        tag: "div",
        key: None,
        attrs: [],
        children: [
          RenderedElement(
            tag: "p",
            key: None,
            attrs: [],
            children: [RenderedText("Functional Component")],
          ),
          RenderedElement(
            tag: "p",
            key: None,
            attrs: [],
            children: [RenderedText("Changed")],
          ),
        ],
      ),
    ],
  )))
}

pub fn fc_props_change_test() {
  let fc = fn(ctx, _) { #(ctx, []) }

  let original_props = dynamic.from(["hello"])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: original_props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Original Functional Component")],
            ),
          ],
        ),
      ],
    )

  let new_props = dynamic.from(["changed"])

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: new_props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Functional Component")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Props Changed")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Replace(RenderedComponent(
    fc: fc,
    key: None,
    props: new_props,
    hooks: ordered_map.new(),
    children: [
      RenderedElement(
        tag: "div",
        key: None,
        attrs: [],
        children: [
          RenderedElement(
            tag: "p",
            key: None,
            attrs: [],
            children: [RenderedText("Functional Component")],
          ),
          RenderedElement(
            tag: "p",
            key: None,
            attrs: [],
            children: [RenderedText("Props Changed")],
          ),
        ],
      ),
    ],
  )))
}

pub fn patch_to_json_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("great"),
              attrs: [],
              children: [RenderedText("Great")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("big"),
              attrs: [],
              children: [RenderedText("Big")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> patch.patch_to_json(True)
  |> json.to_string
  |> should.equal(
    "[
      \"Update\",
      null,
      {
          \"0\": [
              \"Update\",
              null,
              {
                  \"1\": [
                      \"Replace\",
                      {
                          \"type\": \"p\",
                          \"attrs\": {\"spkt-key\":\"great\"},
                          \"0\": \"Great\"
                      }
                  ],
                  \"2\": [
                      \"Insert\",
                      {
                          \"type\": \"p\",
                          \"attrs\": {\"spkt-key\":\"big\"},
                          \"0\": \"Big\"
                      }
                  ],
                  \"3\": [
                      \"Move\",
                      1,
                      [
                          \"NoOp\"
                      ]
                  ]
              }
          ]
      }
    ]"
    |> normalize_json_str(),
  )
}

pub fn patch_to_json_replace_list_with_component_test() {
  let fc = fn(ctx, _) { #(ctx, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("great"),
              attrs: [],
              children: [RenderedText("Great")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("big"),
              attrs: [],
              children: [RenderedText("big")],
            ),
            RenderedElement(
              tag: "p",
              key: Some("world"),
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let fc2 = fn(ctx, _) { #(ctx, []) }

  let second =
    RenderedComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: Some("hello"),
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedComponent(
              fc: fc2,
              key: Some("fc2"),
              props: props,
              hooks: ordered_map.new(),
              children: [
                RenderedElement(tag: "div", key: None, attrs: [], children: []),
              ],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> patch.patch_to_json(True)
  |> json.to_string
  |> should.equal(
    "[
      \"Update\",
      null,
      {
          \"0\": [
              \"Update\",
              null,
              {
                  \"1\": [
                      \"Replace\",
                      {
                          \"type\": \"component\",
                          \"0\": {
                              \"type\": \"div\",
                              \"attrs\": {}
                          }
                      }
                  ],
                  \"2\": [
                      \"Remove\"
                  ],
                  \"3\": [
                      \"Remove\"
                  ]
              }
          ]
      }
    ]"
    |> normalize_json_str(),
  )
}

fn normalize_json_str(json: String) {
  json
  |> string.replace("\n", "")
  |> string.replace(" ", "")
}

pub fn op_code_test() {
  op_code(NoOp, False)
  |> should.equal("0")

  op_code(Update(None, None), False)
  |> should.equal("1")

  op_code(Replace(RenderedElement("div", None, [], [])), False)
  |> should.equal("2")

  op_code(Insert(RenderedElement("div", None, [], [])), False)
  |> should.equal("3")

  op_code(Remove, False)
  |> should.equal("4")

  op_code(Change(""), False)
  |> should.equal("5")

  op_code(Move(0, NoOp), False)
  |> should.equal("6")

  op_code(NoOp, False)
  |> should.equal("0")

  op_code(Update(None, None), True)
  |> should.equal("Update")

  op_code(Replace(RenderedElement("div", None, [], [])), True)
  |> should.equal("Replace")

  op_code(Insert(RenderedElement("div", None, [], [])), True)
  |> should.equal("Insert")

  op_code(Remove, True)
  |> should.equal("Remove")

  op_code(Change(""), True)
  |> should.equal("Change")

  op_code(Move(0, NoOp), True)
  |> should.equal("Move")
}
