# Swift on server

This repository contains the source code of the [swiftonserver.com](https://swiftonserver.com/) website.

## Dependencies

To enable image compression, install the following tools:

```sh
brew install optipng jpegoptim
```

## Environment variables

Set the required environment variables:

```sh
export SWIFTINIT_ACCOUNT="XXX"
export SWIFTINIT_API_KEY="XXX"
export SWIFTINIT_TARGET="swift-on-server.articles:main/Articles"
```

## Build

Run the following command to create a release build:

```sh
make dist
```
