# Templating with Swift-Mustache

When you're working on a backend, you'll often need to generate HTML or other text-based formats. Some common examples include rendering web pages and sending emails.

One popular way to generate text-based output is to use a templating engine. A templating engine is a tool that lets you define a template with placeholders for dynamic content. You can then fill in the placeholders with actual values to generate the final output.

In this tutorial, you'll learn how to use the ``Mustache`` library to generate text-based output in Swift.

## What is Mustache?

[Mustache](https://mustache.github.io/) is a logic-less templating language. It's called "logic-less" because there are no complex statements in Mustache templates. Mustache templates are also used by [this blog](https://github.com/swift-on-server/blog).

Unlike Leaf, which is Swift-specific, Mustache templates can be used in any language that has a Mustache implementation. Mustache is low-complexity, which also improves performance.

## Adding Swift-Mustache to Your Project

First, you need to add the Swift-Mustache package to your project. You can do this by adding the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/hummingbird-project/swift-mustache", from: "2.0.0-beta.1"),
```

Then, add the `Mustache` library to your target dependencies:

```swift
.product(name: "Mustache", package: "swift-mustache"),
```

## Using Mustache Templates

Here's an example of a simple Mustache template:

```html
<main>
    <h1>{{ title }}</h1>
    <p>{{ body }}</p>
</main>
```

Create a `templates` directory in your project, and save this template as `short-port.mustache` in the `templates` directory.

In this template, `{{ title }}` and `{{ body }}` are placeholders for dynamic content. You can fill in these placeholders with actual values using the `Mustache` library.

Here's how you can use the `Mustache` library to render this template:

```swift
import Mustache

let library = MustacheLibrary("/path/to/templates/")
```

``MustacheLibrary`` loads all the templates from the specified directory. You can then use the `render` method to render a template. This also enables templates to embed other templates.

Then, create a struct to hold the data you want to render:

```swift
struct ShortPost {
    let title: String
    let body: String
}
```

You can then render the template like this:

```swift
let shortPost = ShortPost(title: "Hello, World!", body: "This is a short post.")

let rendered = try library.render(
    shortPost,
    withTemplate: "short-post"
)
```

The `render` method takes the data you want to render and the name of the template file. It returns the rendered output as a `String`.

In some scenarios, the custom data may contain HTML tags. By default, these are escaped. This means that the HTML tags are displayed as text rather than being rendered as HTML. To render the HTML tags, you can render it as raw by using a three-brace syntax `{{{` and `}}}`:

```html
<main>
    <h1>{{ title }}</h1>
    <p>{{{ body }}}</p>
</main>
```

In this scenario, the `body` property will be rendered as raw HTML whereas the `title` property will be escaped.

## Arrays

You can also use arrays in your Mustache templates. This is useful when you want to render a list of items. Here's an example:

```html
<ul>
    {{#items}}
    <li>{{ name }}</li>
    {{/items}}
</ul>
```

Save this as `items.mustache` in the `templates` directory. You can then render this template with an array of items:

```swift
struct Item {
    let name: String
}

let items = [
    Item(name: "Item 1"),
    Item(name: "Item 2"),
    Item(name: "Item 3")
]

let rendered = try library.render(
    ["items": items],
    withTemplate: "items"
)
```

In this example, the `items` array is passed to the `render` method as a dictionary. The `{{#items}}` and `{{/items}}` tags are used to create a 'section' that is repeated for each item in the array.

The nested `{{ name }}` tag is replaced with the `name` property of each item in the array. Within the scope of a section, the `{{ name }}` tag is replaced with the `name` property of each item in the array.

If your array contains the raw ``String`` values, you won't need to access the `name` property. Instead, you can directly access the array's value:

```html
<ul>
    {{#items}}
    <li>{{.}}</li>
    {{/items}}
</ul>
```

In this example, the `{{.}}` tag is replaced with the value of each item in the array.

### Empty Arrays

Sometimes, you may want to render a different section of the template when an array is empty. You can do this using the `{{^items}}` tag:

```htmla
{{#posts}}
  <h2><a href="{{link}}">{{title}}</a></h2>
{{/posts}}
{{^posts}}
  <p>No posts found.</p>
{{/posts}}
```

In this example, the `{{#posts}}` section is rendered if the `posts` array contains data. If the `posts` array is empty, the `{{^posts}}` section is rendered instead.

As you've seen, `Swift-Mustache` library provides a lightweight way to generate text-based output in Swift. The library has [more to offer](https://mustache.github.io/mustache.5.html), such as partials and lambdas. You can explore these features to create more complex templates.

Finally, [swift-mustache](https://github.com/hummingbird-project/swift-mustache) has some extra features, [template inheritance](https://docs.hummingbird.codes/2.0/documentation/hummingbird/templateinheritance/) and [transforms](https://docs.hummingbird.codes/2.0/documentation/hummingbird/transforms/). This makes mustache even more powerful to work with.
