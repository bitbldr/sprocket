import gleam/option.{None, Some}
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html.{article, code_text, h1, h2, p, text}
import docs/utils/codeblock.{codeblock}
import docs/components/hello_button.{HelloButtonProps, hello_button}
import docs/utils/common.{example}

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
                "Components let you encapsulate markup and functionality into independent and composable pieces. This page demonstrates how to use components to build a UI.",
              ),
            ],
          ),
          h2([], [text("Components as Building Blocks")]),
          p(
            [],
            [
              text(
                "Components are the fundamental building blocks of your app, allowing you to create modular, reusable, and easy-to-maintain code.",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "A component is a function that takes a context and props as arguments, and it may utilize hooks (we will cover hooks more in depth a
                bit later) to manage state and effects, and returns a list of child elements.",
              ),
            ],
          ),
          p(
            [],
            [
              text("Here is a simple example component we'll call "),
              code_text([], "hello_button"),
              text(
                " that renders a button. We'll also make use of some Tailwind CSS classes here to style our button, but you can use whichever style framework you prefer.",
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

                pub type HelloButtonProps {
                  HelloButtonProps(label: Option(String))
                }

                pub fn hello_button(ctx: Context, props: HelloButtonProps) {
                  let HelloButtonProps(label) = props

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
                "As you can see, we've defined our component and it's props. The component takes a context and props as arguments, and then renders a button with the label passed in as a prop. If no label is passed in, the button will render with the default label of \"Click me!\".",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "Because of Gleam's type system guarantees, components can be type checked at compile time, and the compiler will ensure that the component is given the correct props and that the component returns a valid view.",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "To use this new component in a parent view, we can simply pass it into the ",
              ),
              code_text([], "component"),
              text(" function along with the props we want to pass in."),
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
          p([], [text("Here is our component in action:")]),
          example([component(hello_button, HelloButtonProps(label: None))]),
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
                  ButtonProps(label: Some(\"Say Hello!\")),
                ),
                ",
          ),
          example([
            component(hello_button, HelloButtonProps(label: Some("Say Hello!"))),
          ]),
          p([], [text("Excellent! Now our button has a proper label.")]),
          p(
            [],
            [
              text(
                "But our humble button isn't very interesting yet. Let's say we want to add some functionality to our button. We can do that by
                implementing some events and state management via hooks, which we'll cover in the next couple sections.",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
