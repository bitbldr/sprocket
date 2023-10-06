import gleam/option.{None, Some}
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html/attributes.{class}
import sprocket/html.{article, code_text, div, h1, h2, i, p, span, text}
import docs/components/common.{codeblock, example}
import docs/components/example_button.{ExampleButtonProps, example_button}
import docs/components/toggle_button.{ToggleButtonProps, toggle_button}
import docs/components/product_list.{
  Product, ProductListProps, example_coffee_products, product_card, product_list,
}

pub type ComponentsPageProps {
  ComponentsPageProps
}

pub fn components_page(ctx: Context, _props: ComponentsPageProps) {
  render(
    ctx,
    [
      article(
        [],
        [
          h1([], [text("Components")]),
          p(
            [],
            [
              text(
                "Components are the fundamental building blocks that encapsulate markup and functionality into independent and composable pieces.
                This page will explore some key concepts of components and demonstrate how to use them to build rich user interfaces.",
              ),
            ],
          ),
          h2([], [text("Stateful Components")]),
          p(
            [],
            [
              text(
                "A Stateful Component is a function that takes a context and props as arguments and returns a list of child elements. These components may also
                utilize hooks to manage events, state and effects. Let's take a look at an example component.",
              ),
            ],
          ),
          p(
            [],
            [
              text("We're going to create a simple component called "),
              code_text([], "example_button"),
              text(
                " that takes an optional label and renders a button. We will use Tailwind CSS to style our button, but you can use any classes or style framework you prefer.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
                import gleam/option.{None, Option, Some}
                import sprocket/context.{Context}
                import sprocket/component.{render}
                import sprocket/html.{button, text}
                import sprocket/html/attributes.{class}

                pub type ExampleButtonProps {
                  ExampleButtonProps(label: Option(String))
                }

                pub fn example_button(ctx: Context, props: ExampleButtonProps) {
                  let ExampleButtonProps(label) = props

                  render(
                    ctx,
                    [
                      button(
                        [class(\"p-2 bg-blue-500 hover:bg-blue-600 active:bg-blue-700 text-white rounded\")],
                        [
                          text(case label {
                            Some(label) -> label
                            None -> \"Click me!\"
                          }),
                        ],
                      ),
                    ],
                  )
                }
                ",
          ),
          p(
            [],
            [
              text(
                "As you can see, we've defined our component and it's prop types. The component takes context and props as arguments and renders a button. If no label is specified, the button will render with the default label of \"Click me!\".",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "Because Gleam is statically typed, our component is guaranteed to receive the required props of the correct type. We can be confident that our component will render as expected without having to worry about a large category of errors occuring during runtime.",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "To use this new component in a parent view, we can simply pass it into ",
              ),
              code_text([], "component"),
              text(" along with the props we want to pass in."),
            ],
          ),
          p(
            [],
            [
              text(
                "Let's take a look at an example of a page view component that uses the button component we defined above.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
                pub type PageViewProps {
                  PageViewProps
                }

                pub fn page_view(ctx: Context, _props: PageViewProps) {
                  render(
                    ctx,
                    [
                      div(
                        [],
                        [
                          component(
                            button,
                            ButtonProps(label: None),
                          ),
                        ],
                      ),
                    ]
                  )
                }
                ",
          ),
          p([], [text("Here is our rendered component:")]),
          example([component(example_button, ExampleButtonProps(label: None))]),
          p(
            [],
            [
              text(
                "That's looking pretty good, but let's add a label to our button. We can do that by passing in a label prop to our component.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
                component(
                  button,
                  ButtonProps(label: Some(\"Add to Cart\")),
                ),
                ",
          ),
          example([
            component(
              example_button,
              ExampleButtonProps(label: Some("Add to Cart")),
            ),
          ]),
          p([], [text("Excellent! Now our button has a proper label.")]),
          p(
            [],
            [
              text(
                "But our humble button isn't very interesting yet. Let's say we want to add some functionality to our button. We can do that by
                implementing some events and state management via hooks.",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "We'll cover events, state management and hooks in-depth a bit later. For now, we'll just add a simple state hook
                and callback hook to our button component which will toggle the label when the button is clicked. We'll call our new component ",
              ),
              code_text([], "toggle_button"),
              text(" and instead of rendering a string label, we'll pass in a "),
              code_text([], "render_label"),
              text(
                " prop as a function that takes the current state of the toggle and renders the content of our button accordingly.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
            import sprocket/context.{Context, Element}
            import sprocket/component.{render}
            import sprocket/html.{button}
            import sprocket/html/attributes.{class, on_click}
            import sprocket/hooks.{WithDeps, dep}
            import sprocket/hooks/callback.{callback}
            import sprocket/internal/identifiable_callback.{CallbackFn}
            import sprocket/hooks/state.{state}

            pub type ToggleButtonProps {
              ToggleButtonProps(render_label: fn(Bool) -> Element)
            }

            pub fn toggle_button(ctx: Context, props: ToggleButtonProps) {
              let ToggleButtonProps(render_label) = props

              // add a state hook to track the active state, we'll cover hooks in more detail later
              use ctx, is_active, set_active <- state(ctx, False)

              // add a callback hook to toggle the active state
              use ctx, on_toggle_active <- callback(
                ctx,
                CallbackFn(fn() {
                  set_active(!is_active)
                  Nil
                }),
                WithDeps([dep(is_active)]),
              )

              render(
                ctx,
                [
                  button(
                    [
                      class(case is_active {
                        True ->
                          \"rounded-lg text-white px-3 py-2 bg-green-700 hover:bg-green-800 active:bg-green-900\"
                        False ->
                          \"rounded-lg text-white px-3 py-2 bg-blue-500 hover:bg-blue-600 active:bg-blue-700\"
                      }),
                      on_click(on_toggle_active),
                    ],
                    [render_label(is_active)],
                  ),
                ],
              )
            }
            ",
          ),
          p(
            [],
            [
              text("We've added a "),
              code_text([], "state"),
              text(" hook to track the active state of our button and a "),
              code_text([], "callback"),
              text(
                " hook to toggle the active state when the button is clicked. We've also added a ",
              ),
              code_text([], "render_label"),
              text(
                " prop to our component to allow us to customize the label of our toggle button depending on whether the toggle is active or inactive.",
              ),
            ],
          ),
          p([], [text("Now let's use our new component in a parent view.")]),
          codeblock(
            "gleam",
            "
            pub type PageViewProps {
              PageViewProps
            }

            pub fn page_view(ctx: Context, _props: PageViewProps) {
              render(
                ctx,
                [
                  div(
                    [],
                    [
                      component(
                        toggle_button,
                        ToggleButtonProps(render_label: fn(toggle) {
                          case toggle {
                            True ->
                              span(
                                [],
                                [
                                  i([class(\"fa-solid fa-check mr-2\")], []),
                                  text(\"Added to Cart!\"),
                                ],
                              )
                            False ->
                              span(
                                [],
                                [
                                  i([class(\"fa-solid fa-cart-shopping mr-2\")], []),
                                  text(\"Add to Cart\"),
                                ],
                              )
                          }
                        }),
                      ),
                    ],
                  ),
                ],
              )
            }
            ",
          ),
          p([], [text("Here is our rendered stateful component:")]),
          example([
            component(
              toggle_button,
              ToggleButtonProps(render_label: fn(toggle) {
                case toggle {
                  True ->
                    span(
                      [],
                      [
                        i([class("fa-solid fa-check mr-2")], []),
                        text("Added to Cart!"),
                      ],
                    )
                  False ->
                    span(
                      [],
                      [
                        i([class("fa-solid fa-cart-shopping mr-2")], []),
                        text("Add to Cart"),
                      ],
                    )
                }
              }),
            ),
          ]),
          h2([], [text("Stateless Functional Components")]),
          p(
            [],
            [
              text(
                "Not every component will require state management or hooks. In these cases a stateless functional component can be used. Stateless functional components are simply regular 
                functions that encapsulate markup and functionality into independent and composable pieces. The function is called directly from the render function (opposed to wrapping it in ",
              ),
              code_text([], "component"),
              text(
                " as seen previously with stateful components). Let's look at an example of a stateless functional component that renders a product card.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
              type Product {
                Product(
                  id: Int,
                  name: String,
                  description: String,
                  img_url: String,
                  qty: String,
                  price: Float,
                )
              }

              pub fn product_card(product: Product, actions: Option(List(Element)) {
                let Product(
                  name: name,
                  description: description,
                  img_url: img_url,
                  qty: qty,
                  price: price,
                  ..,
                ) = product

                div(
                  [
                    class(
                      \"flex flex-row bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700\",
                    ),
                  ],
                  [
                    div(
                      [class(\"w-1/3 rounded-l-lg overflow-hidden\")],
                      [
                        img([
                          class(\"object-cover h-52 w-full\"),
                          src(img_url),
                          alt(\"product image\"),
                        ]),
                      ],
                    ),
                    div(
                      [class(\"flex-1 flex flex-col p-5\")],
                      [
                        div(
                          [class(\"flex-1 flex flex-row\")],
                          [
                            div(
                              [class(\"flex-1\")],
                              [
                                h5_text(
                                  [
                                    class(
                                      \"text-xl font-semibold tracking-tight text-gray-900 dark:text-white\",
                                    ),
                                  ],
                                  name,
                                ),
                                div_text([class(\"py-2 text-gray-500\")], description),
                              ],
                            ),
                            div(
                              [],
                              [
                                div(
                                  [class(\"flex-1 flex flex-col text-right\")],
                                  [
                                    div_text(
                                      [
                                        class(
                                          \"text-xl font-bold text-gray-900 dark:text-white\",
                                        ),
                                      ],
                                      \"$\" <> float.to_string(price),
                                    ),
                                    div_text([class(\"text-sm text-gray-500\")], qty),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        case actions {
                          None -> div([], [])
                          Some(actions) ->
                            div([class(\"flex flex flex-row justify-end\")], actions)
                        },
                      ],
                    ),
                  ],
                )
              }
            ",
          ),
          p(
            [],
            [
              text(
                "To render this component we call it directly from the render function, passing any arguments the function takes, which in this case is a ",
              ),
              code_text([], "Product"),
              text(
                " record and an optional list of actions, which we will leave as ",
              ),
              code_text([], "None"),
              text(" for now."),
            ],
          ),
          codeblock(
            "gleam",
            "
              pub fn product(ctx: Context, _props: ProductProps) {
                let some_product = 
                  Product(
                    id: 2255,
                    name: \"Bamboo Cutting Board\",
                    description: \"This sustainable bamboo cutting board is perfect for slicing and dicing vegetables, fruits, and meats. The natural antibacterial properties of bamboo ensure a hygienic cooking experience.\",
                    img_url: \"https://images.pexels.com/photos/6489734/pexels-photo-6489734.jpeg\",
                    qty: \"12 x 8 inches\",
                    price: 24.99,
                  )
                
                render(
                  ctx,
                  [
                    div(
                      [class(\"flex flex-col\")],
                      [
                        product_card(some_product, None)
                      ]
                    ),
                  ],
                )
              }
            ",
          ),
          example([
            div(
              [class("flex flex-col")],
              [
                product_card(
                  Product(
                    id: 2255,
                    name: "Bamboo Cutting Board",
                    description: "This sustainable bamboo cutting board is perfect for slicing and dicing vegetables, fruits, and meats. The natural antibacterial properties of bamboo ensure a hygienic cooking experience.",
                    img_url: "https://images.pexels.com/photos/6489734/pexels-photo-6489734.jpeg",
                    qty: "12 x 8 inches",
                    price: 24.99,
                  ),
                  None,
                ),
              ],
            ),
          ]),
          p(
            [],
            [
              text(
                "You may have noticed that we are using a few functions named after HTML elements such as ",
              ),
              code_text([], "div"),
              text(" and "),
              code_text([], "img"),
              text(
                ". These are Stateless Functional Components that are provided by the Sprocket HTML module and are used to render HTML elements. You can find a full list of available functions in the ",
              ),
              code_text([], "sprocket/html"),
              text(" module."),
            ],
          ),
          h2([], [text("Components as Building Blocks")]),
          p(
            [],
            [
              text(
                "Components are the fundamental building blocks of Sprocket applications. They can be composed together to create rich user interfaces. Let's take a look at an example of a view that uses the ",
              ),
              code_text([], "toggle_button"),
              text(" and the "),
              code_text([], "product_card"),
              text(
                " components we defined earlier to create a simple product component.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
              pub fn product(ctx: Context, _props: PageViewProps) {
                render(
                  ctx,
                  [
                    div(
                      [class(\"flex flex-col\")],
                      [
                        product_card(
                          Product(
                            id: 2259,
                            name: \"Organic Aromatherapy Candle\",
                            description: \"Create a fresh ambiance with this organic aromatherapy candle. Hand-poured with pure essential oils, the fresh scent of citrus will brighten up your room.\",
                            img_url: \"https://images.pexels.com/photos/7260249/pexels-photo-7260249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2\",
                            qty: \"1 candle\",
                            price: 19.99,
                          ),
                          Some([
                            component(
                              toggle_button,
                              ToggleButtonProps(render_label: fn(toggle) {
                                case toggle {
                                  True ->
                                    span(
                                      [],
                                      [
                                        i([class(\"fa-solid fa-check mr-2\")], []),
                                        text(\"Added to Cart!\"),
                                      ],
                                    )
                                  False ->
                                    span(
                                      [],
                                      [
                                        i([class(\"fa-solid fa-cart-shopping mr-2\")], []),
                                        text(\"Add to Cart\"),
                                      ],
                                    )
                                }
                              }),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ],
                )
              }
            ",
          ),
          example([
            div(
              [class("flex flex-col")],
              [
                product_card(
                  Product(
                    id: 2259,
                    name: "Organic Aromatherapy Candle",
                    description: "Create a fresh ambiance with this organic aromatherapy candle. Hand-poured with pure essential oils, the fresh scent of citrus will brighten up your room.",
                    img_url: "https://images.pexels.com/photos/7260249/pexels-photo-7260249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
                    qty: "1 candle",
                    price: 19.99,
                  ),
                  Some([
                    component(
                      toggle_button,
                      ToggleButtonProps(render_label: fn(toggle) {
                        case toggle {
                          True ->
                            span(
                              [],
                              [
                                i([class("fa-solid fa-check mr-2")], []),
                                text("Added to Cart!"),
                              ],
                            )
                          False ->
                            span(
                              [],
                              [
                                i([class("fa-solid fa-cart-shopping mr-2")], []),
                                text("Add to Cart"),
                              ],
                            )
                        }
                      }),
                    ),
                  ]),
                ),
              ],
            ),
          ]),
          p(
            [],
            [
              text("As you can see, we've composed our stateless "),
              code_text([], "product_card"),
              text(" component with our stateful "),
              code_text([], "toggle_button"),
              text(
                " to create a somewhat trivial product listing. But this is the power of components. They can be combined to create rich user interfaces.",
              ),
            ],
          ),
          h2([], [text("Dynamic Components and "), code_text([], "keyed")]),
          p(
            [],
            [
              text("Components can be conditionally rendered using "),
              code_text([], "case"),
              text(
                " statements as seen in some of the previous examples, but they can also be dynamically rendered as a list of elements using any of Gleam's list functions such as ",
              ),
              code_text([], "list.map"),
              text(" or "),
              code_text([], "list.filter"),
              text("."),
            ],
          ),
          p(
            [],
            [
              text("It's important to use "),
              code_text([], "keyed"),
              text(
                " when rendering elements that may change so that the diffing algorithm can keep track of them and thier states across renders. Let's
                take a look at an example of a component that renders a list of products, each with their own state.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
              pub type ProductListProps {
                ProductListProps(products: List(Product))
              }

              pub fn product_list(ctx: Context, props: ProductListProps) {
                let ProductListProps(products) = props

                // ignore the state management for now, we'll cover that in a later section

                render(
                  ctx,
                  [
                    div(
                      [],
                      list.map(
                        products,
                        fn (p) {
                          keyed(p.id, 
                            component(
                              product,
                              ProductProps(product: p),
                            )
                          )
                        },
                      ),
                    ),
                  ],
                )
              }
            ",
          ),
          example([
            component(
              product_list,
              ProductListProps(products: example_coffee_products()),
            ),
          ]),
          p(
            [],
            [
              text(
                "As you can see, we've defined a component that takes a list of products as props, and then renders a list of product cards. Each product card has it's own
                state (a boolean indicating whether an item is in the cart or not), and we can filter products from the list by clicking \"Not Interested\". Because we are using the ",
              ),
              code_text([], "keyed"),
              text(
                " function, the diffing algorithm can keep track of each product card and will reconcile elements that have changed position, keeping their state in-tact.",
              ),
            ],
          ),
          p(
            [],
            [
              text("It's important to use the "),
              code_text([], "keyed"),
              text(
                " function anytime you are dynamically rendering elements or a list of elements that may change.",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
