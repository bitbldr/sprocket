import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/html.{article, div, h1, h2, li, p, span, text, ul}
import sprocket/html/attributes.{class}
import docs/utils/code.{codeblock}

pub type IntroductionPageProps {
  IntroductionPageProps
}

pub fn introduction_page(socket: Socket, _props: IntroductionPageProps) {
  render(
    socket,
    [
      article(
        [],
        [
          h1([], [text("Introduction")]),
          p(
            [],
            [
              text(
                "
                    Welcome to the official documentation of Sprocket, a real-time server-side components framework for Gleam! In this guide, we'll
                    cover the core concepts of Sprocket, but some prerequisite knowledge of Gleam is recommended. Gleam is a type-safe functional language designed
                    to harness the power of the Erlang Beam virtual machine. Whether you are a seasoned Gleam enthusiast or new to this exciting language,
                    this documentation will serve as your roadmap to building highly scalable, robust, and efficient server-side components.
                    ",
              ),
            ],
          ),
          div(
            [
              class(
                "flex flex-row p-4 mb-4 text-sm text-yellow-800 rounded-lg bg-yellow-50 dark:bg-gray-800 dark:text-yellow-300",
              ),
            ],
            [
              div([class("mr-2")], [span([class("text-xl")], [text("🚧")])]),
              div(
                [class("flex-grow-1")],
                [
                  span([class("font-bold")], [text("Important Note: ")]),
                  text(
                    "Sprocket is under heavy development and this documentation is a work in progress! Please proceed with caution as things are likely to change.",
                  ),
                ],
              ),
              div([class("ml-2")], [span([class("text-xl")], [text("🚧")])]),
            ],
          ),
          h2([], [text("What is Sprocket?")]),
          p(
            [],
            [
              text(
                "
                      Sprocket is a new framework based on existing patterns that empowers developers to build real-time applications with ease, embracing the strengths of
                      Gleam's type-safety and the Erlang Beam virtual machine's concurrency and fault-tolerance capabilities. It offers an expressive and
                      intuitive syntax, making it effortless to reason about complex systems and craft maintainable codebases.
                    ",
              ),
            ],
          ),
          p(
            [class("italic")],
            [
              span([class("font-bold")], [text("Fun fact: ")]),
              text(
                "Sprocket is named after the humble bicycle gear that enables the wheels to spin effortlessly! Also, this documentation is completely powered by it!",
              ),
            ],
          ),
          h2([], [text("Why Sprocket?")]),
          p(
            [],
            [
              text(
                "
                      Sprocket was born out of a vision to bridge the gap between functional programming, type-safety, and the real-time demands of modern
                      applications. With Sprocket, developers can seamlessly construct concurrent and distributed systems without compromising on the rigor
                      of Gleam's static typing. By leveraging the Erlang Beam VM, Sprocket enables high-throughput, fault-tolerant, and real-time communication
                      channels that cater to the needs of modern web applications, IoT devices, and more.
                    ",
              ),
            ],
          ),
          h2([], [text("Key Features")]),
          p(
            [],
            [
              ul(
                [],
                [
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Type-Safety: ")]),
                      text(
                        "Gleam's static typing guarantees robustness and correctness in your codebase, reducing the likelihood of runtime errors and
                      enabling early bug detection during compilation.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Concurrency: ")]),
                      text(
                        "Sprocket harnesses the power of the Erlang Beam VM, providing lightweight processes and easy-to-use abstractions for
                      concurrent programming.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span(
                        [class("font-bold")],
                        [text("Real-time Components: ")],
                      ),
                      text(
                        "Build reactive and real-time applications effortlessly by designing modular and reusable components with Sprocket's
                      declarative approach.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Fault-Tolerance: ")]),
                      text(
                        "The Erlang Beam VM's battle-tested fault-tolerance mechanisms ensure that your applications stay resilient even under
                      adverse conditions.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Extensibility: ")]),
                      text(
                        "Sprocket is designed to be extensible, allowing you to integrate seamlessly with existing Erlang or Elixir projects and libraries.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Scalability: ")]),
                      text(
                        "With Sprocket, scaling your application is a breeze thanks to the Erlang VM's distributed and fault-tolerant nature.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Open Source: ")]),
                      text(
                        "Sprocket is completely open-source and free to use. Contributions are welcome and encouraged!",
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          h2([], [text("Who Should Read This Documentation?")]),
          p(
            [],
            [
              text(
                "
                    This documentation is tailored to developers, architects, and enthusiasts who are eager to explore the world of UI functional programming with Gleam. Whether you are a seasoned Erlang/Elixir developer looking to venture into Gleam or a newcomer to the Erlang ecosystem, this documentation will guide you through the process of building real-time server-side components with Sprocket.
                  ",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "
                    Familiarity with functional programming concepts and the Erlang ecosystem will be beneficial, but not mandatory, as this documentation aims to be accessible to developers from various backgrounds.
                  ",
              ),
            ],
          ),
          h2([], [text("Getting Started")]),
          p(
            [],
            [
              text(
                "
                    Before diving in, lets make sure you have Gleam and the necessary dependencies installed on your system. If you haven't already, head over to the Gleam installation guide and follow the instructions for your operating system.

                    Let's embark on this journey together and unlock the true potential of real-time server-side components with Sprocket and Gleam! Happy coding!
                    ",
              ),
              text(
                "
                     Once you have Gleam installed, you can create a new project with the following command:
                    ",
              ),
              codeblock("sh", "gleam new sprocket-demo"),
              text(
                "
                    Then add sprocket as a dependency:
                    ",
              ),
              codeblock("sh", "gleam add sprocket"),
              text(
                "
                    That's it! Now we can begin our journey and unlock the true potential of real-time server-side components with Sprocket and Gleam!
                    ",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
