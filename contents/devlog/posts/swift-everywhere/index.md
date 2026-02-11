---
type: devlog
title: "Swift Everywhere - A Vision"
description: "Outlining my thoughts on the future of Swift"
image: ./assets/cover.jpg
publication: "2025/2/12 9:00:00"
featured: false
tags:
authors:
    - joannis-orlandos
---

# Swift Everywhere

As I'm enjoying my time at [ARCtic Conference](https://arcticonference.com/), and I meet a lot of iOS developers, I can't help but realise Swift is not one community. It's two.

Us folks in the OpenSource ecosystem are eagerly and enthusiastically pushing Swift onto a LOT of new platforms. Some iOS developers feel left out, others have FOMO with all the new features added.

It's made me realise that we as a Swift community are not quite a whole. But I think we can be if we align our ambitions.

## The New C

We all know C and C++ are (generally) unsafe. And writing code that's reliable and scalable is hard because of it. As Ben Cohen puts it well, you can align languages along three main axis.
Here are my definitions:

- **Safety:** Memory- and concurrency safety are critical for our software-driven world. Governments even started mandating memory-safe code in their contracts.
- **Fast:** A language's ability to produce programs with low-memory usage and a high throughput of work.
- **Easy:** The ability for a human (developer) to understand the code. Think of cyclomatic complexity, expressiveness and brevity.

As I alluded to, any unsafe language is immediately a no-go for me, and many developers like my. And only a handful of languages are **really** fast like C or C++. There are many languages that are easy to write, but often at the cost of the former two.

Let's eliminate the first bulletpoint, **safety**, as being a nice to have. It's a mandatory.

### Carrying a Legacy

The reality, however, is that there is a lot of existing code out there. And even with AI, it's infeasible to rewrite all of it in a new language and be confident. Maybe it's coincidence, but Microsoft has started doing this with Windows, and the instability in recent times is horrendous. I don't think it's related to their choice of language - but rewrites are risky!

And as such, we need a fourth measurement for the _feasibility_ of migrating to this new language - **interop**.

Swift, like many languages, has interop with C. But we have way more. In fact, it's the only language that has interop with C++ - making it an excellent candidate for a huge number of existing codebases. On top of C++ there are great libraries for Java, JavaScript and even Python interop!

## A Super Power

We've established that Swift is feasible for all these use cases. But I don't think most developers really realise the super power they've learned when they started with Swift.

Swift has been the de-facto language for Apple platforms since its inception. Apps need to be **fast**, so your users get the least lag. They need to be **safe**, so your app doesn't crash or have obscure bugs. And it needs to be **easy** to write, so you can rapidly iterate it and ship! And **interop** allowed you to mix Swift into your existing Objective-C codebase.

Backends have very similar needs; **fast** code allows you to scale your app, and be cost effective. **Safety** prevents a variety of attacks and data leaks. **Easy** development allows you to iterate faster. And **interop** allows you to migrate existing code, or use libraries from other ecosystems.

Swift on Server has been tremendously successful. Apple uses it for their backend services on a _massive_ scale! But they're not alone. We've got thousands of active users in the community writing code every day. And I'm always surprised to learn at conferences that people who are not a part of the community use it, too.

To quote a user I recently met in person;
> The Java ecosystem is very enterprise oriented. They'll refuse changes because it's not applicable at their scale. But in Swift, we've got libraries and tools designed for our _current_ scale, allowing us to be productive, while still being confident in our ability to grow huge.

But Swift doesn't end with Apple and backend. We support [Android](https://www.swift.org/blog/exploring-the-swift-sdk-for-android/) too. Thanks to **Java Interop**, it blends in with your Android UIs written in Java. This allows you to create a single codebase for both iOS and Android, without losing **safety** and **expressivity**.

On top of that, WASM allows Swift to [run in the browser](https://elementary.codes/) too! And with Embedded Swift mode, your browser app can be < 100KB in size!

## Red Ocean

Swift is a great language, as we've seen. But as I see this ecosystem grow into a technical marvel, I don't see adoption go as fast as I'd like. In a way, I _expected_ more interest, given the amount of effort and enthusiasm poured in. Swift runs in all these exciting new places, making it check all the boxes. But as a community, we don't talk about our successes nearly enough.

We have to talk and showcase ourselves more. Swift is great and it's here to stay!

For companies, I often hear the argument that Swift on Server is brilliant but lacks engineers. And Swift on Server engineers are bummed by the lack of published job openings. Obviously there's a discoverability gap between the two.

**If anyone wants to share their experiences, please do reach out to me!** Whether a talk, blog post, podcast or otherwise. I'd love to help you out!
And if you're a teacher who's interested in teaching Swift, we can definitely make something happen together!

While the software market is saturated, we still have plenty of things to stand out with. We have a huge amount of features and tools other ecosystems can only dream of.

### Blue Ocean

That being said, surely we can innovate further. We don't need to compete in an oversaturated market. There is one huge ecosystem that's daunting to write for.

In Embedded Systems, code is written in **unsafe** languages, **slow and hard** to iterate all for performance. As these systems are largely written in C and C++, **interop** is the only means forward. Swift can and must fill the gap.

At [Wendy](https://wendy.sh) we're currently working on this exact problems - emphasizing on Embedded Linux and robotics. I hope we can extend this same experience to Microcontrollers and other platforms soon.

## Conclusion

If you're a Swift developer today and you're not using your superpowers yet - _get started and share your story!_ There's a huge community of eager like-minded people working on this daily.

_Not your thing, or unsure or unfamiliar about this direction?_ I'd love to hear your concerns and point you in the right direction - or help address these issues.