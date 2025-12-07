We want to add support for 'client components' where sprocket components can be mounted to a DOM
node in the browser. To achieve this, we will make use of the multi-target compilation of gleam
where we can compile to both Erlang and JavaScript. This will allow us to share code between
the server and client while still being able to run the client code in the browser.

We will need to refactor the repository structure to separate the client and server code. We can
create 3 new gleam projects/directories: `client/`, `server/`, and `shared/`. The `client/`
directory will contain all the code related to the client-side components, while the `server/`
directory will contain the server-side code. The `shared/` directory will contain code that is
shared between the client and server, allowing us to maximize code reuse.

The `client/` project will be compiled to JavaScript using gleam's JavaScript target, while the
`server/` project will be compiled to Erlang. The `shared/` project can be compiled to both targets,
allowing us to use the same code in both the client and server.

To set up the new structure, we can follow these steps:

```
gleam new client \
  && gleam new server \
  && gleam new shared
```

We will move all the existing code into the server project, and refactor any shared code into the
shared project.

Next, we will need to configure the dependencies between the projects. The `client/` and `server/`
projects will depend on the `shared/` project. We can do this by adding the `shared/` project as a
dependency in the `gleam.toml` files of both the `client/` and `server/` projects.

Finally, we will need to set up the build process to compile both the client and server projects.
Do not use make or any custom build scripts; instead, rely on gleam's built-in build system and
commands, node's package scripts, and update any CI/CD configurations accordingly.

With this new structure in place, we can now start developing client components that can be
mounted to DOM nodes in the browser, while still being able to share code with the server-side
components.

Client components can be mounted in one of two ways:

1. **Server Mounting**: The server can render the initial HTML with placeholders for the client
   components. When the client-side JavaScript loads, it can automatically find these placeholders
   and mount the corresponding client components to them. This can be achieved by using data
   attributes or specific class names to identify the placeholders in the DOM. We will add a new
   html element called `mount` that can be used by server components to indicate where client
   components should be mounted.

2. **Client Mounting**: The client-side code can provide an API that allows developers to manually
   mount client components to specific DOM nodes. This can be useful for dynamic applications where
   components need to be mounted based on user interactions or for single-page applications (SPAs)
   where the page is not rendered by a sprocket server component.

We will eventually rewrite the existing sprocket client TypeScript code as gleam code and move it
to the `client/` project. This will allow us to have a consistent codebase and take full advantage
of gleam's type system and features on both the client and server sides. The client API will then
allow mounting of gleam client components to DOM nodes in the browser or connecting to
server-rendered components, as the existing Typescript API does.

You are a Gleam architect who specializes in providing your expertise to guide others on how to best
design a new feature in the codebase.

Using this informal feature description, create a formal Feature Design Document (FDD)
docs/features/client_components/fdd.md that outlines the architecture necessary to implement the
'client components' feature in the sprocket framework. The FDD should include diagrams where
appropriate, detailed descriptions of the components involved, their interactions, and the
high-level specifications for each part of the system. Additionally, identify any potential
challenges or considerations that need to be addressed during implementation.

This FDD will serve as a blueprint for the development plan that will follow, ensuring that all
requirements are clearly defined, understood and captured as development tasks.

Analyze the codebase and repository structure as needed and do any additional research to ensure the
FDD is comprehensive and accurate.
