# Writing Articles

All articles for the site are written using the Markdown file format.

## Directory Structure

To contribute an article, create a new folder within the `contents/blog/posts/` directory.

The folder structure follows the pattern `{year}/{slug}`. If you are just starting a draft, don't worry too much about the specific slug; we can tweak it before publication. Inside your article folder, create a standard `index.md` file.

## Planning an Article

The recommended way to start is by creating an **outline**. This acts as a roadmap for your post, consisting of a bullet-point list of chapters (Headings 1, 2, and 3).

We recommend adding a one-word tag to each bullet point to define its purpose. Common tags include:

* **intro**: Setting the stage.
* **theory**: Front-loading necessary concepts or information.
* **practice**: Hands-on coding sections.
* **conclusion**: A recap of what was learned.

Here is an example outline:

```md
# Getting Started with Hummingbird 2
[short metadata description]

## What is Hummingbird?
[intro]

## Adding the Dependency
[practice]

## Hummingbird and Service Lifecycle
[theory]

## Creating a Web Server
[practice]

## Running Your App
[practice]

## What are Routes?
[theory]

## Adding a Route
[practice]

## Responding to Requests
[practice]

## Where to go from here?
[conclusion]
```

**General Guideline:** We recommend presenting only one "theory" block at a time, followed immediately by "practice." However, we understand that some deep-dive articles may naturally be more theoretical.

Practical blocks should ideally end with a moment of reflection. This allows the user to verify their progress—for example, a screenshot of a web browser or a code block displaying the expected terminal output.

## Writing the Sample Code

We suggest writing the sample code *before* the prose. Programmers naturally gravitate towards the code they want to explain, so having it ready makes writing the tutorial easier.

Ideally, keep sample code constrained to specific snippets.

## Writing the Tutorial

Once your sample code is ready, copy your outline and code snippets into your editor. Since we use [Toucan](https://toucansites.com/), you can use the static site generator to preview your work locally. 

**Drafting Advice:** Don't be too critical of your first draft. Write down your thoughts freely and refine them later. You will likely spot missing explanations, ordering issues, or complex phrasing upon your second read-through.

## Polishing

When your story flows logically, create a draft PR and tag [Joannis](https://github.com/joannis) and [Tibor](https://github.com/tib).

We will review the draft and provide suggestions for both the text and the code. We tend to make many small edits to ensure clarity for the reader. **Please don't be intimidated by this;** it is a standard part of our quality assurance process.

While we handle the final polish, you can speed up the process by checking the following:

### Flesch-Kincaid Readability Score

We analyze the text using the [Hemingway Editor](https://hemingwayapp.com/). This tool highlights complex sentences and suggests simpler alternatives.

Most first drafts start with a low score—this is normal. The score can usually be improved quickly by applying the editor's suggestions.

### Word Choice

In the article itself, we strive for an authoritative voice. This means we try to avoid personal pronouns like "you," "I," or "we." We believe the articles are scrutinized enough to warrant a confident, objective tone.

### Passive Voice

As part of maintaining an authoritative tone, we strive to remove use of [passive voice](https://www.grammarly.com/blog/passive-voice/) wherever possible.

### Section Length

We aim to keep articles in digestible chunks. This applies to both the text sections and the length of sample code blocks.
