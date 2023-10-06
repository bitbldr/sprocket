import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{
  a_text, article, div, h1, h2, h3, li, ol, p, p_text, span_text, text,
}
import sprocket/html/attributes.{class, href, target}
import docs/components/common.{codeblock}

pub type GettingStartedPageProps {
  GettingStartedPageProps
}

pub fn getting_started_page(ctx: Context, _props: GettingStartedPageProps) {
  render(
    ctx,
    [
      article(
        [],
        [
          h1([], [text("Getting Started")]),
          h2([], [text("Prerequisites")]),
          p(
            [],
            [
              text("Before we can get started, we'll need a few things:"),
              ol(
                [],
                [
                  li(
                    [],
                    [
                      span_text([class("font-bold")], "Gleam:"),
                      text(
                        " Statically typed functional language that compiles to Erlang. Install using the ",
                      ),
                      a_text(
                        [
                          href("https://gleam.run/getting-started/"),
                          target("_blank"),
                        ],
                        "official installation guide",
                      ),
                      text("."),
                    ],
                  ),
                  li(
                    [],
                    [
                      span_text([class("font-bold")], "NodeJS:"),
                      text(
                        " JavaScript runtime built on Chrome's V8 JavaScript engine. Install using the ",
                      ),
                      a_text(
                        [
                          href("https://nodejs.org/en/download/"),
                          target("_blank"),
                        ],
                        "official installation guide",
                      ),
                      text("."),
                    ],
                  ),
                  li(
                    [],
                    [
                      span_text([class("font-bold")], "Yarn:"),
                      text(
                        " Fast, reliable, and secure dependency management. Install using the ",
                      ),
                      a_text(
                        [
                          href("https://yarnpkg.com/getting-started/install"),
                          target("_blank"),
                        ],
                        "official installation guide",
                      ),
                      text("."),
                    ],
                  ),
                ],
              ),
            ],
          ),
          h2([], [text("Setup")]),
          h3([], [text("Method 1: Clone the starter project (Recommended)")]),
          p_text([], "This method is the easiest way to get started."),
          ol(
            [],
            [
              li(
                [],
                [
                  div(
                    [],
                    [
                      text("Clone the starter repository from GitHub"),
                      codeblock(
                        "bash",
                        "
                        # Clone the starter repository from GitHub
                        git clone https://github.com/bitbldr/sprocket-starter.git

                        # Change into the project directory
                        cd sprocket-starter
                        ",
                      ),
                    ],
                  ),
                ],
              ),
              li([], [text("Install dependencies"), codeblock("bash", "yarn")]),
              li(
                [],
                [text("Start the server"), codeblock("bash", "yarn watch")],
              ),
            ],
          ),
          h3([], [text("Method 2: Add to existing project")]),
          p(
            [],
            [
              text(
                "This method is a bit more involved and assumes you already have a Gleam project. This section is intended to be a high-level overview of the steps involved rather than a comprehensive guide. When in doubt, refer to the ",
              ),
              a_text(
                [
                  href("https://github.com/bitbldr/sprocket-starter.git"),
                  target("_blank"),
                ],
                "starter repository on GitHub.",
              ),
            ],
          ),
          ol(
            [],
            [
              li(
                [],
                [
                  div(
                    [],
                    [
                      text("Add Sprocket dependency"),
                      codeblock(
                        "bash",
                        "
                        # Add Sprocket as a dependency in your gleam.toml
                        gleam add sprocket
                        ",
                      ),
                    ],
                  ),
                ],
              ),
              li(
                [],
                [
                  div(
                    [],
                    [
                      text(
                        "Add client-side dependencies with the following commands",
                      ),
                      codeblock(
                        "bash",
                        "
                        # Initialize a new NodeJS project, if you don't already have one
                        npm init -y

                        # Add sprocket-js as a client dependency
                        npm install sprocket-js
                        ",
                      ),
                    ],
                  ),
                ],
              ),
              li(
                [],
                [
                  div(
                    [],
                    [
                      text(
                        "Sprocket needs to be initialized by the client in order to establish a persistent connection to the server. Add the following contents to your client entrypoint file (e.g. app.js)",
                      ),
                      codeblock(
                        "javascript",
                        "
                        import { connect } from \"sprocket-js\";

                        const hooks = {};

                        window.addEventListener(\"DOMContentLoaded\", () => {
                          const csrfToken = document
                            .querySelector(\"meta[name=csrf-token]\")
                            ?.getAttribute(\"content\");

                          if (csrfToken) {
                            let livePath =
                              window.location.pathname === \"/\"
                                ? \"/live\"
                                : window.location.pathname.split(\"/\").concat(\"live\").join(\"/\");

                            connect(livePath, {
                              csrfToken,
                              hooks,
                              // // Optionally, specify an element to mount to
                              // targetEl: document.querySelector(\"#app\") as Element,
                            });
                          } else {
                            console.error(\"Missing CSRF token\");
                          }
                        });
                        ",
                      ),
                    ],
                  ),
                ],
              ),
              li(
                [],
                [
                  div(
                    [],
                    [
                      text(
                        "Tailwind configuration is a bit involved and is out of scope for this guide. If you wish to follow along with the same styles in this documentation, you can install tailwind by following the instructions in the ",
                      ),
                      a_text(
                        [href("https://tailwindcss.com/docs/installation")],
                        "Tailwind CSS installation guide",
                      ),
                      text(" and taking a look at the configuration in the "),
                      a_text(
                        [
                          href(
                            "https://github.com/bitbldr/sprocket-starter.git",
                          ),
                          target("_blank"),
                        ],
                        "starter repository on GitHub.",
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "That's it! Now we can begin our journey to learning how to build real-time server-side components with Sprocket!",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
