import gleam/json
import gleam/string
import gleeunit/should
import gleam/dynamic
import gleam/option.{None, Some}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedText,
}
import sprocket/internal/patch.{Change, Insert, Move, NoOp, Replace, Update}
import sprocket/internal/utils/ordered_map

// gleeunit test functions end in `_test`
pub fn text_change_test() {
  let fc = fn(socket, _) { #(socket, []) }
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
  let fc = fn(socket, _) { #(socket, []) }
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
  let fc = fn(socket, _) { #(socket, []) }
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
  let fc = fn(socket, _) { #(socket, []) }
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
  let fc = fn(socket, _) { #(socket, []) }
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
  let fc = fn(socket, _) { #(socket, []) }
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

pub fn attribute_change_test() {
  let fc = fn(socket, _) { #(socket, []) }
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

  let fc1 = fn(socket, _) { #(socket, []) }

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

  let fc2 = fn(socket, _) { #(socket, []) }

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
  let fc = fn(socket, _) { #(socket, []) }

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
  let fc = fn(socket, _) { #(socket, []) }
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
  |> patch.patch_to_json
  |> json.to_string
  |> should.equal(
    "[
      1,
      null,
      {
          \"0\": [
              1,
              null,
              {
                  \"1\": [
                      2,
                      {
                          \"type\": \"p\",
                          \"attrs\": {\"spkt-key\":\"great\"},
                          \"0\": \"Great\"
                      }
                  ],
                  \"2\": [
                      3,
                      {
                          \"type\": \"p\",
                          \"attrs\": {\"spkt-key\":\"big\"},
                          \"0\": \"Big\"
                      }
                  ],
                  \"3\": [
                      6,
                      1,
                      [
                          0
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
  let fc = fn(socket, _) { #(socket, []) }
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

  let fc2 = fn(socket, _) { #(socket, []) }

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
  |> patch.patch_to_json
  |> json.to_string
  |> should.equal(
    "[
      1,
      null,
      {
          \"0\": [
              1,
              null,
              {
                  \"1\": [
                      2,
                      {
                          \"type\": \"component\",
                          \"0\": {
                              \"type\": \"div\",
                              \"attrs\": {}
                          }
                      }
                  ],
                  \"2\": [
                      4
                  ],
                  \"3\": [
                      4
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
