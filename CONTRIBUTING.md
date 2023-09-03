# Contributing to Sprocket

Thank you for considering contributing to Sprocket! We appreciate your interest and support. By contributing, you can help make Sprocket better and more robust for everyone. This guide will help you understand how to contribute to the project effectively.

## Table of Contents

- [Contributing to Sprocket](#contributing-to-sprocket)
  - [Table of Contents](#table-of-contents)
  - [Ways to Contribute](#ways-to-contribute)
  - [Reporting Issues](#reporting-issues)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
  - [Development Setup](#development-setup)
  - [Run Unit Tests](#run-unit-tests)

## Ways to Contribute

There are several ways you can contribute to Sprocket:

- **Reporting Issues**: If you encounter any problems or bugs while using Sprocket, please let us know by creating an issue in the GitHub repository.
- **Suggesting Enhancements**: If you have ideas for new features or improvements to Sprocket, feel free to open an issue to discuss and suggest them.
- **Writing Code**: You can contribute to the project by writing code, fixing bugs, or implementing new features. See the [Pull Requests](#pull-requests) section for more information.
- **Testing**: Help us ensure the quality and reliability of Sprocket by testing the library, reporting issues, and verifying bug fixes.
- **Documentation**: Improve the project's documentation by suggesting changes, providing examples, or adding missing information.

## Reporting Issues

If you come across any issues or bugs while using Sprocket, please help us by reporting them. When reporting issues, provide as much information as possible, including steps to reproduce the problem and any relevant error messages or logs. You can create a new issue in the [Issue Tracker](https://github.com/sprocket/sprocket/issues).

## Suggesting Enhancements

If you have ideas for new features, enhancements, or improvements to Sprocket, we would love to hear them. You can submit your suggestions by creating a new issue in the [Issue Tracker](https://github.com/sprocket/sprocket/issues). Please provide detailed information about your suggestion, including its purpose and potential benefits.

## Pull Requests

If you want to contribute code to Sprocket, you can do so by opening a pull request. Here's a high-level overview of the process:

1. Fork the Sprocket repository.
2. Create a new branch for your changes.
3. Make your code changes, following the [Code Style Guidelines](#code-style-guidelines).
4. Write tests to cover your changes.
5. Ensure all tests pass.
6. Commit your changes and push them to your forked repository.
7. Open a pull request in the main Sprocket repository.

Once your pull request is opened, it will be reviewed by the maintainers. They may provide feedback or request additional changes. Collaborate with the maintainers to address any concerns and iterate on your changes. After the review process, your pull request will be merged if it meets the project's requirements.

## Development Setup

To set up a development environment for working on Sprocket, follow the steps below:

1. Clone the Sprocket repository:
```
git clone https://github.com/bitbldr/sprocket.git
```

1. Install the required dependencies:
```
gleam deps download
yarn
```

1. Start the development server:
```
yarn run watch
```

1. Open your web browser and visit `http://localhost:3000` to see the sample app.

## Run Unit Tests

This will run both client (ts) and server (gleam) unit tests
```sh
yarn test
```