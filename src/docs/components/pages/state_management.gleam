import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{article, code_text, h1, h2, p, text}
import docs/components/say_hello.{SayHelloProps, say_hello}
import docs/utils/common.{example}
import docs/utils/code.{codeblock}

pub type StateManagementPageProps {
  StateManagementPageProps
}

pub fn state_management_page(socket: Socket, _props: StateManagementPageProps) {
  render(
    socket,
    [
      article(
        [],
        [
          h1([], [text("State Management")]),
          p(
            [],
            [
              text("State is managed using reducer fuctions and the "),
              code_text([], "reducer"),
              text(" hook. We'll also utilize the "),
              code_text([], "callback"),
              text(" hook to help us dispatch events to the reducer."),
            ],
          ),
          h2([], [text("Reducer Functions")]),
          p(
            [],
            [
              text(
                "Reducer functions are functions that take a state and message and return a new state. They are used to update state in response to events. Using our ",
              ),
              code_text([], "hello_button"),
              text(
                " component as an example, we can define a function that updates the state when the button is clicked.",
              ),
            ],
          ),
          p([], [text("First we define our state struct and message types:")]),
          codeblock(
            "gleam",
            "
            type Model {
              Model(selection: Option(Int), options: List(HelloOption))
            }

            type Msg {
              NoOp
              SayHello
            }
          ",
          ),
          p(
            [],
            [
              text(
                "Here we're storing a list of options and the index of the selected option in the state.",
              ),
            ],
          ),
          p([], [text("Next we define our reducer function:")]),
          codeblock(
            "gleam",
            "
            fn update(model: Model, msg: Msg) -> Model {
              case msg {
                NoOp -> model
                SayHello ->
                  Model(..model, selection: Some(int.random(0, list.length(model.options))))
              }
            }
            ",
          ),
          h2([], [text("Introducing the Reducer Hook")]),
          p(
            [],
            [
              text("Let's declare a "),
              code_text([], "reducer"),
              text(" hook in our component that uses our update function:"),
            ],
          ),
          codeblock(
            "gleam",
            "
            use socket, State(Model(selection: selection, options: options), dispatch) <- reducer(
              socket,
              initial(hello_options()),
              update,
            )
            ",
          ),
          p(
            [],
            [
              text(
                "You can see here we got back the current state of the reducer, which we can use in our component. ",
              ),
              text("Notice, we also got back a "),
              code_text([], "dispatch"),
              text(
                " function from the reducer. The dispatch function is used to send messages to the reducer which will update the state and trigger a re-render.",
              ),
            ],
          ),
          p(
            [],
            [
              text("The use of the "),
              code_text([], "initial"),
              text(
                " function is used to intiialize the state of the reducer. This will only be applied when the component is first rendered.",
              ),
            ],
          ),
          h2([], [text("Introducing the Callback Hook")]),
          p(
            [],
            [
              text(
                "We need one more thing to complete our component. We need to define a function that will be called when the button is clicked. It's important that we define this as a callback function using the ",
              ),
              code_text([], "callback"),
              text(
                " hook so that we can ensure the id of the callback function is maintained between renders, preventing a new id being created and sent to the client on every update.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
            use socket, on_say_hello <- callback(
              socket,
              CallbackFn(fn() { dispatch(SayHello) }),
              WithDeps([]),
            )
            ",
          ),
          h2([], [text("Putting it all together")]),
          p(
            [],
            [
              text(
                "We now have all the pieces we need to create a more interesting button that updates whenever it is clicked. Again, we are using Tailwind CSS to style our button but you can use whichever styling framework you prefer.",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
            import gleam/int
            import gleam/list
            import gleam/pair
            import gleam/option.{None, Option, Some}
            import sprocket/socket.{Socket}
            import sprocket/component.{render}
            import sprocket/hooks.{WithDeps}
            import sprocket/hooks/reducer.{State, reducer}
            import sprocket/hooks/callback.{callback}
            import sprocket/internal/identifiable_callback.{CallbackFn}
            import sprocket/html.{button, div, span, text}
            import sprocket/html/attributes.{class, on_click}

            type HelloOption =
              #(String, String)

            fn hello_options() -> List(HelloOption) {
              [
                #(\"English\", \"Hello\"),
                #(\"Spanish\", \"Hola\"),
                #(\"French\", \"Bonjour\"),
                #(\"German\", \"Hallo\"),
                #(\"Italian\", \"Ciao\"),
                #(\"Portuguese\", \"Olá\"),
                #(\"Hawaiian\", \"Aloha\"),
                #(\"Chinese (Mandarin)\", \"你好,(Nǐ hǎo)\"),
                #(\"Japanese\", \"こんにち, (Konnichiwa)\"),
                #(\"Korean\", \"안녕하세, (Annyeonghaseyo)\"),
                #(\"Arabic\", \"مرحب, (Marhaba)\"),
                #(\"Hindi\", \"नमस्त, (Namaste)\"),
                #(\"Turkish\", \"Merhaba\"),
                #(\"Dutch\", \"Hallo\"),
                #(\"Swedish\", \"Hej\"),
                #(\"Norwegian\", \"Hei\"),
                #(\"Danish\", \"Hej\"),
                #(\"Greek\", \"Γεια σας,(Yia sas)\"),
                #(\"Polish\", \"Cześć\"),
                #(\"Swahili\", \"Hujambo\"),
              ]
            }

            type Model {
              Model(selection: Option(Int), options: List(HelloOption))
            }

            type Msg {
              NoOp
              SayHello
            }

            fn update(model: Model, msg: Msg) -> Model {
              case msg {
                NoOp -> model
                SayHello ->
                  Model(..model, selection: Some(int.random(0, list.length(model.options))))
              }
            }

            fn initial(options: List(HelloOption)) -> Model {
              Model(selection: None, options: options)
            }

            pub type SayHelloProps {
              SayHelloProps
            }

            pub fn say_hello(socket: Socket, _props: SayHelloProps) {
              use socket, State(Model(selection: selection, options: options), dispatch) <- reducer(
                socket,
                initial(hello_options()),
                update,
              )

              use socket, on_say_hello <- callback(
                socket,
                CallbackFn(fn() { dispatch(SayHello) }),
                WithDeps([]),
              )

              // find the selected option using the selection index and list of options
              let hello =
                selection
                |> option.map(fn(i) {
                  list.at(options, i)
                  |> option.from_result()
                })
                |> option.flatten()

              render(
                socket,
                [
                  div(
                    [],
                    [
                      button(
                        [
                          class(\"p-2 bg-blue-500 hover:bg-blue-700 text-white rounded\"),
                          on_click(on_say_hello),
                        ],
                        [text(\"Say Hello\")],
                      ),
                      ..case hello {
                        None -> []
                        Some(hello) -> [
                          span([class(\"ml-2\")], [text(pair.second(hello))]),
                          span(
                            [class(\"ml-2 text-gray-400 bold\")],
                            [text(pair.first(hello))],
                          ),
                        ]
                      }
                    ],
                  ),
                ],
              )
            }
            ",
          ),
          example([component(say_hello, SayHelloProps)]),
          p(
            [],
            [
              text(
                "Now we have a button that says hello in a random language every time it is clicked.",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "Remember, all of these state changes are happening on the server. Events are being passed from the client to the server, the latest view is rendered and a minimal diff update is sent back to the client a which is then patched into the DOM. Very cool!",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "These are just two of the hooks that are available in Sprocket. There are many more to explore! We'll cover hooks more in-depth in the next section.",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
