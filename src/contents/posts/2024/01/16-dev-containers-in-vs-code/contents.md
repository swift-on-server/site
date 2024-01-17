---
slug: developing-with-swift-in-visual-studio-code
title: Developing with Swift in Visual Studio Code
description: Learn how to set up your Visual Studio Code for Swift development using Docker, Dev Containers and the Swift for VS Code extension.
date: 2024/01/16
tags: Swift, VSCode
author: Joannis Orlandos
authorLink: https://x.com/JoannisOrlandos
company: Unbeatable Software B.V.
companyLink: https://unbeatable.software/
duration: 10 minutes
---

Swift is a great language for developing applications for Apple platforms, and is easily set up using Xcode.
However, Xcode is only available for macOS, and does not support a wide variety of extensions.
For this reason, many Server-Side Swift developers prefer to use Visual Studio Code for their development.

Visual Studio Code is a free and open-source code editor developed by Microsoft for Windows, Linux and macOS.

## What are Dev Containers?

Dev Containers are a way to develop in a containerized environment. Containers are a way to package software in a format that can be run on any platform, such as Linux, macOS or Windows.
You can think of them as a lightweight alternative to virtual machines. In most of our tutorials, we'll provide a dev container for you to use. This allows you to set up all prerequisites for a tutorial in a single step.

### Prerequisites

First, download Visual Studio Code from [https://code.visualstudio.com/download/](https://code.visualstudio.com/download/) and install it for your platform.

Then, once Visual Studio Code is installed, download and install Docker. The easiest way is to use the Docker Desktop installer for your platform: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

## Opening a Project

Make sure Docker (Desktop) is running, ready, and has sufficient resources allocated. You can do this by opening the Docker Desktop application and going to the "Resources" tab.
Swift needs at least 4GB of memory to compile, so make sure you have at least 4GB of memory allocated to Docker.

Open Visual Studio Code and click on the "Open Folder" button in the welcome screen. Select the folder containing the starter project.
In the bottom-right of the window, you'll see a blue button with the text "Reopen in Container". Click on it to reopen the project in a Dev Container.

If you don't see the button, you can also open the command palette (Ctrl+Shift+P on Windows/Linux, Cmd+Shift+P on macOS) and search for "Reopen in Container".

![Reopen in Container](open-in-container.png)

Visual Studio Code will now start downloading or building the Dev Container. This may take a while, as it needs to download the Swift toolchain and other dependencies.

Once it's done, you'll see a new window with the project open. You can now start developing!

### Running the Code

In the left sidebar, you'll see a "Run" tab. Click on it to open the Run view. You'll see a "Run" button with a green arrow. Click on it to run the project.

On the bottom-right of the window, you'll see a terminal window pop up. This is the terminal inside the Dev Container, and shows the output of the program.
You can also find the debugger right next to that terminal window, which has LLDB integration.

Once the program is done running, you'll see the output in the terminal window:

![Program Output](program-output.png)

If you see the above output, congratulations! You've successfully set up your development environment for Swift development using Visual Studio Code and Dev Containers.