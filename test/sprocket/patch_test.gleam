import gleam/dynamic
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import sprocket/context.{Element}
import sprocket/internal/patch.{
  Change, Insert, Move, NoOp, Remove, Replace, Update, op_code,
}
import sprocket/internal/reconcile.{
  ReconciledAttribute, ReconciledComponent, ReconciledElement, ReconciledText,
}
import sprocket/internal/utils/ordered_map
import sprocket/internal/utils/unique

const empty_element = Element(tag: "div", attrs: [], children: [])

// gleeunit test functions end in `_test`
pub fn text_change_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Changed")],
          ),
        ],
      ),
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Changed")],
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> should.equal(Update(
    None,
    Some([
      #(
        0,
        Update(
          None,
          Some([
            #(
              0,
              Insert(
                ReconciledElement(unique.from_string("b"), "p", None, [], [
                  ReconciledText("Hello"),
                ]),
              ),
            ),
            #(
              1,
              Insert(
                ReconciledElement(unique.from_string("c"), "p", None, [], [
                  ReconciledText("Changed"),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn add_child_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Great")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Big")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("d"),
                  tag: "p",
                  key: None,
                  attrs: [],
                  children: [ReconciledText("Great")],
                ),
              ),
            ),
            #(
              2,
              Insert(
                ReconciledElement(
                  id: unique.from_string("e"),
                  tag: "p",
                  key: None,
                  attrs: [],
                  children: [ReconciledText("Big")],
                ),
              ),
            ),
            #(
              3,
              Insert(
                ReconciledElement(
                  id: unique.from_string("c"),
                  tag: "p",
                  key: None,
                  attrs: [],
                  children: [ReconciledText("World")],
                ),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn add_move_child_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "p",
            key: Some("great"),
            attrs: [],
            children: [ReconciledText("Great")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "p",
            key: Some("big"),
            attrs: [],
            children: [ReconciledText("Big")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("d"),
                  tag: "p",
                  key: Some("great"),
                  attrs: [],
                  children: [ReconciledText("Great")],
                ),
              ),
            ),
            #(
              2,
              Insert(
                ReconciledElement(
                  id: unique.from_string("e"),
                  tag: "p",
                  key: Some("big"),
                  attrs: [],
                  children: [ReconciledText("Big")],
                ),
              ),
            ),
            #(3, Move(from: 1, patch: NoOp)),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn add_move_update_child_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [ReconciledAttribute("class", "round")],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "p",
            key: Some("great"),
            attrs: [],
            children: [ReconciledText("Great")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "p",
            key: Some("big"),
            attrs: [],
            children: [ReconciledText("Big")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [
              ReconciledAttribute("class", "round"),
              ReconciledAttribute("class", "blue"),
            ],
            children: [ReconciledText("Blue"), ReconciledText("World")],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("d"),
                  tag: "p",
                  key: Some("great"),
                  attrs: [],
                  children: [ReconciledText("Great")],
                ),
              ),
            ),
            #(
              2,
              Insert(
                ReconciledElement(
                  id: unique.from_string("e"),
                  tag: "p",
                  key: Some("big"),
                  attrs: [],
                  children: [ReconciledText("Big")],
                ),
              ),
            ),
            #(
              3,
              Move(
                from: 1,
                patch: Update(
                  attrs: Some([
                    ReconciledAttribute("class", "round"),
                    ReconciledAttribute("class", "blue"),
                  ]),
                  children: Some([
                    #(0, Change("Blue")),
                    #(1, Insert(ReconciledText("World"))),
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "p",
            key: Some("great"),
            attrs: [],
            children: [ReconciledText("Great")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "p",
            key: Some("big"),
            attrs: [],
            children: [ReconciledText("Big")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "div",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("Blue"), ReconciledText("World")],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("d"),
                  tag: "p",
                  key: Some("great"),
                  attrs: [],
                  children: [ReconciledText("Great")],
                ),
              ),
            ),
            #(
              2,
              Insert(
                ReconciledElement(
                  id: unique.from_string("e"),
                  tag: "p",
                  key: Some("big"),
                  attrs: [],
                  children: [ReconciledText("Big")],
                ),
              ),
            ),
            #(
              3,
              Move(
                from: 1,
                patch: Replace(
                  ReconciledElement(
                    id: unique.from_string("c"),
                    tag: "div",
                    key: Some("world"),
                    attrs: [],
                    children: [ReconciledText("Blue"), ReconciledText("World")],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
}

pub fn remove_middle_child_in_list_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("three"),
            attrs: [],
            children: [ReconciledText("Three")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("f"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four"), ReconciledText("and a half")],
          ),
          ReconciledElement(
            id: unique.from_string("f"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
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
                  children: Some([#(1, Insert(ReconciledText("and a half")))]),
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("f"),
            tag: "li",
            key: Some("three"),
            attrs: [],
            children: [ReconciledText("Three")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("f"),
                  tag: "li",
                  key: Some("three"),
                  attrs: [],
                  children: [ReconciledText("Three")],
                ),
              ),
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("f"),
            tag: "li",
            key: Some("three"),
            attrs: [],
            children: [ReconciledText("Three")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [
              ReconciledText("Five"),
              ReconciledComponent(
                fc,
                None,
                props,
                ordered_map.new(),
                ReconciledText("and some change"),
              ),
            ],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("f"),
                  tag: "li",
                  key: Some("three"),
                  attrs: [],
                  children: [ReconciledText("Three")],
                ),
              ),
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
                      Insert(ReconciledComponent(
                        fc,
                        None,
                        props,
                        ordered_map.new(),
                        ReconciledText("and some change"),
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> should.equal(NoOp)
}

pub fn ignored_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          reconcile.ReconciledIgnoreUpdate(
            ReconciledElement(
              id: unique.from_string("b"),
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [ReconciledText("One")],
            ),
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          reconcile.ReconciledIgnoreUpdate(
            ReconciledElement(
              id: unique.from_string("b"),
              tag: "li",
              key: Some("one"),
              attrs: [],
              children: [ReconciledText("Changed")],
            ),
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> should.equal(NoOp)
}

pub fn shift_list_with_keys_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "ul",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("f"),
            tag: "li",
            key: Some("uno"),
            attrs: [],
            children: [ReconciledText("Uno")],
          ),
          ReconciledElement(
            id: unique.from_string("g"),
            tag: "li",
            key: Some("dos"),
            attrs: [],
            children: [ReconciledText("Dos")],
          ),
          ReconciledElement(
            id: unique.from_string("h"),
            tag: "li",
            key: Some("tres"),
            attrs: [],
            children: [ReconciledText("Tres")],
          ),
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "li",
            key: Some("one"),
            attrs: [],
            children: [ReconciledText("One")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "li",
            key: Some("two"),
            attrs: [],
            children: [ReconciledText("Two")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "li",
            key: Some("four"),
            attrs: [],
            children: [ReconciledText("Four")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "li",
            key: Some("five"),
            attrs: [],
            children: [ReconciledText("Five")],
          ),
        ],
      ),
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
              Replace(
                ReconciledElement(
                  id: unique.from_string("f"),
                  tag: "li",
                  key: Some("uno"),
                  attrs: [],
                  children: [ReconciledText("Uno")],
                ),
              ),
            ),
            #(
              1,
              Replace(
                ReconciledElement(
                  id: unique.from_string("g"),
                  tag: "li",
                  key: Some("dos"),
                  attrs: [],
                  children: [ReconciledText("Dos")],
                ),
              ),
            ),
            #(
              2,
              Replace(
                ReconciledElement(
                  id: unique.from_string("h"),
                  tag: "li",
                  key: Some("tres"),
                  attrs: [],
                  children: [ReconciledText("Tres")],
                ),
              ),
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [ReconciledAttribute("class", "bold")],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [ReconciledAttribute("class", "italic")],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [
              ReconciledAttribute("class", "bold"),
              ReconciledAttribute("class", "italic"),
            ],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Changed")],
          ),
        ],
      ),
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
                  ReconciledAttribute("class", "bold"),
                  ReconciledAttribute("class", "italic"),
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

  let fc1 = fn(ctx, _) { #(ctx, empty_element) }

  let first =
    ReconciledComponent(
      fc: fc1,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Original Functional Component")],
          ),
        ],
      ),
    )

  let fc2 = fn(ctx, _) { #(ctx, empty_element) }

  let second =
    ReconciledComponent(
      fc: fc2,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Functional Component")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Changed")],
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> should.equal(
    Replace(ReconciledComponent(
      fc: fc2,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Functional Component")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Changed")],
          ),
        ],
      ),
    )),
  )
}

pub fn fc_props_change_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }

  let original_props = dynamic.from(["hello"])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: original_props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Original Functional Component")],
          ),
        ],
      ),
    )

  let new_props = dynamic.from(["changed"])

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: new_props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Functional Component")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Props Changed")],
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> should.equal(
    Replace(ReconciledComponent(
      fc: fc,
      key: None,
      props: new_props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Functional Component")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: None,
            attrs: [],
            children: [ReconciledText("Props Changed")],
          ),
        ],
      ),
    )),
  )
}

pub fn patch_to_json_test() {
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "p",
            key: Some("great"),
            attrs: [],
            children: [ReconciledText("Great")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "p",
            key: Some("big"),
            attrs: [],
            children: [ReconciledText("Big")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> patch.patch_to_json()
  |> json.to_string
  |> should.equal(
    "[
      \"Update\",
      null,
      {\"0\":
        [
          \"Update\",
          null,
          {
              \"1\": [
                  \"Replace\",
                  {
                      \"type\": \"element\",
                      \"id\": \"d\",
                      \"tag\": \"p\",
                      \"attrs\": {},
                      \"events\": [],
                      \"hooks\": [],
                      \"key\": \"great\",
                      \"0\": \"Great\"
                  }
              ],
              \"2\": [
                  \"Insert\",
                  {
                      \"type\": \"element\",
                      \"id\": \"e\",
                      \"tag\": \"p\",
                      \"attrs\": {},
                      \"events\": [],
                      \"hooks\": [],
                      \"key\": \"big\",
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
  let fc = fn(ctx, _) { #(ctx, empty_element) }
  let props = dynamic.from([])

  let first =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledElement(
            id: unique.from_string("c"),
            tag: "p",
            key: Some("great"),
            attrs: [],
            children: [ReconciledText("Great")],
          ),
          ReconciledElement(
            id: unique.from_string("d"),
            tag: "p",
            key: Some("big"),
            attrs: [],
            children: [ReconciledText("big")],
          ),
          ReconciledElement(
            id: unique.from_string("e"),
            tag: "p",
            key: Some("world"),
            attrs: [],
            children: [ReconciledText("World")],
          ),
        ],
      ),
    )

  let fc2 = fn(ctx, _) { #(ctx, empty_element) }

  let second =
    ReconciledComponent(
      fc: fc,
      key: None,
      props: props,
      hooks: ordered_map.new(),
      el: ReconciledElement(
        id: unique.from_string("a"),
        tag: "div",
        key: None,
        attrs: [],
        children: [
          ReconciledElement(
            id: unique.from_string("b"),
            tag: "p",
            key: Some("hello"),
            attrs: [],
            children: [ReconciledText("Hello")],
          ),
          ReconciledComponent(
            fc: fc2,
            key: Some("fc2"),
            props: props,
            hooks: ordered_map.new(),
            el: ReconciledElement(
              id: unique.from_string("f"),
              tag: "div",
              key: None,
              attrs: [],
              children: [],
            ),
          ),
        ],
      ),
    )

  patch.create(first, second)
  |> patch.patch_to_json()
  |> json.to_string
  |> should.equal(
    "[
      \"Update\",
      null,
      {\"0\":
        [
          \"Update\",
          null,
          {
              \"1\": [
                  \"Replace\",
                  {
                      \"type\": \"component\",
                      \"key\": \"fc2\",
                      \"0\": {
                          \"type\": \"element\",
                          \"id\": \"f\",
                          \"tag\": \"div\",
                          \"attrs\": {},
                          \"events\": [],
                          \"hooks\": []
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
  op_code(NoOp)
  |> should.equal("0")

  op_code(Update(None, None))
  |> should.equal("1")

  op_code(
    Replace(ReconciledElement(unique.from_string("a"), "div", None, [], [])),
  )
  |> should.equal("2")

  op_code(
    Insert(ReconciledElement(unique.from_string("b"), "div", None, [], [])),
  )
  |> should.equal("3")

  op_code(Remove)
  |> should.equal("4")

  op_code(Change(""))
  |> should.equal("5")

  op_code(Move(0, NoOp))
  |> should.equal("6")

  op_code(NoOp)
  |> should.equal("0")
}
