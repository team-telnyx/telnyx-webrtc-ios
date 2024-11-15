fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### lint

```sh
[bundle exec] fastlane lint
```

Does a static analysis of the project. Configure the options in .swiftlint.yml

### tests

```sh
[bundle exec] fastlane tests
```

Run unit tests.

### changelog

```sh
[bundle exec] fastlane changelog
```

Create a file with the Changelog output between a specific TAG and HEAD

### generate_docs

```sh
[bundle exec] fastlane generate_docs
```

Generate documentation using Jazzy - HTML docs

### generate_docs_markdown

```sh
[bundle exec] fastlane generate_docs_markdown
```

Generate documentation using SourceDocs - Markdown docs

### generate_full_docs

```sh
[bundle exec] fastlane generate_full_docs
```

Generate HTML and Markdown documentation

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
