# Swift on Server

This repository contains the source code for the [swiftonserver.com](https://swiftonserver.com/) website.

## Dependencies

The website is built using [Toucan](https://toucansites.com/), a static site generator. To get started, you will need to [install](https://toucansites.com/docs/installation/macos/) Toucan (e.g. via Homebrew on macOS):

```sh
brew install toucansites/toucan/toucan
```

To enable image compression for the site, please also install the following tools:

```sh
brew install optipng jpegoptim
```

## Local Development

You can build, watch, and serve the website locally using the following commands.

**Create a development build**

Run this command to generate the site:

```sh
make dev
```

**Watch for changes**

To automatically rebuild the site whenever you modify the source files, execute:

```sh
make watch
```

**Serve the site**

To host the site locally on your machine, run:

```sh
make serve
```

Once the server is running, open [http://localhost:3000/](http://localhost:3000/) in your browser to preview the website.
