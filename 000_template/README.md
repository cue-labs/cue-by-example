# Style Guide

Use this file as a style guide when creating new cue-by-example documents, and
use the file [template.md](template.md) as a template you can copy and adapt.

## Conventions

### Section headings

Use a single H1 heading (`#`), at the top, to indicate the document's title.

On the Markdown line directly underneath the H1 line, include a `<sup>` HTML
element containing your preferred attribution as the document author, and for
each co-author. For example:

---

```
# Using CUE to get ahead in Hollywood
<sup>by [George Clooney](https://www.imdb.com/name/nm0000123/)</sup>
<sup>and [Halle Berry](https://www.imdb.com/name/nm0000932/)</sup>
```

---

... which renders as:

---

# Using CUE to get ahead in Hollywood
<sup>by [George Clooney](https://www.imdb.com/name/nm0000123/)</sup>
<sup>and [Halle Berry](https://www.imdb.com/name/nm0000932/)</sup>

---

Use H2 headings (`##`) to differentiate between isolated, stand-alone
scenarios.

Use H3 headings (`###`) to mark sections within a single scenario.

Use H4 headings (`####`) to name individual steps within a section. This will
allow the step to be linked to by users, which will be useful if a user gets
stuck and needs to post in CUE Slack, asking for some help, and wants to
identify the step they're stuck on.

In the H4 line, prefix the name of each step that the user should perform with
a :arrow_right: icon (`:arrow_right:`).

For example:

---

```
#### :arrow_right: Frobnicate the doodahs

Frobnicating the doodahs remotely is easy, if you remember to loofah the
widgets. To do that, ...
```

---

... which renders as:

---

#### :arrow_right: Frobnicate the doodahs

Frobnicating the doodahs remotely is easy, if you remember to loofah the
widgets. To do that, ...

---

Please include at a minimum:

- an introduction section, covering **at least** the prerequisites the reader
  must be aware of to successfully use the document
- a section containing the steps to follow, with step markers as described
  above
- a conclusion section

### Files

Indicate each file that the user should create:

- with a :floppy_disk: icon (`:floppy_disk:`)
- followed on the same line by the file's path and name in an inline code block
- followed by a fenced code block with a content type preamble, containing the
  file's content.

For example:

---
```` # there are 4 backticks here *solely* to enable the 3 backticks, below, to render
:floppy_disk: `some_file.cue`
```CUE
package cbe123

some_content: "some string"
```
````
---

... which renders as:

---
:floppy_disk: `some_file.cue`
```CUE
package cbe123

some_content: "some string"
```
---

### Shell command blocks

Indicate one or more commands that the user should run in a shell:

- with a :computer: icon (`:computer:`)
- followed on the same line by the word `terminal` in an inline code block
- followed by a fenced code block with a content type of `sh`
- with each command the user needs to run on a line by itself, each with **no
  prefix**
- with any critical comments trailing after their associated command, separated
  by an appropriate shell comment symbol (usually `#`).

The lack of any prefix means that using the "copy" button that GitHub
automatically places at the top right of each code block will give the reader
useful, paste-able text. If you were to include a prefix, such as `$`, then the
reader wouldn't be able to paste the commands directly into a terminal.

Include example output in a separate fenced code block, after the command code
block, to help the user judge if the command has run as expected on their local
machine.

For example:

---

```` # there are 4 backticks here *solely* to enable the 3 backticks, below, to render
:computer: `terminal`
```sh
echo "hello world" | tr 'a-z' 'A-Z' | tr -s 'A-Z'   # this is a really important command
echo 'CUE is awesome!'
```

Expected output:
```
HELO WORLD
CUE is awesome!
```
````

---

... which renders as:

---

:computer: `terminal`
```sh
echo "hello world" | tr 'a-z' 'A-Z' | tr -s 'A-Z'   # this is a really important command
echo 'CUE is awesome!'
```

Expected output:
```
HELO WORLD
CUE is awesome!
```

---

#### Folding lengthy file or shell content

When a file or shell block's contents is long enough that it disrupts the flow
of the guide, consider placing the lengthy content inside a "click-to-expand"
`<details>` HTML element.

This element has 2 parts:

- a short preable that's always visible (the `<summary>`)
- the folded content that's only visible after a click

Please use the folding element as follows:

- Place the element inside a pair of horizontal lines (`<hr>`), to indicate to
  the reader where the unfolded content finishes
- Wrap the file's name in a `<code>` element (instead of single backticks)
- Follow the file's name with the words `(click to open)`
- Place a blank (source) line between the closing `</summary>` tag and the
  opening of the file's fenced code block (<code>```</code>), so that GitHub's
  markdown formatting works correctly

Here's an example of using a `<details>` element to fold a file:

````
Here's a file that you might find useful:

<hr>
<details>
<summary>
:floppy_disk: <code>a_file.cue</code> (click to open)
</summary>

```text
A
long
file
but
not
really
as
this
is
just
an
example
```
</details>
<hr>
````

This renders as follows:

Here's a file that you might find useful:

<hr>
<details>
<summary>
:floppy_disk: <code>a_file.cue</code> (click to open)
</summary>

```text
A
long
file
but
not
really
as
this
is
just
an
example
```
</details>
<hr>

### Warning and Info blocks

If your reader needs to be warned or informed at a specific point in the
document, use a Markdown table like one of the following, with one of the
headings exactly as provided:

---

```
| :exclamation: WARNING :exclamation: |
|:----------------------------------- |
| This warning text must appear on a single line in the markdown source, as if there's a line break then the formatting will break. Whilst this can result in unwieldy source text, the rendered result looks fine. To force a line break, use an HTML `<br>` tag, like this:<br> To force a blank line use two, like this:<br><br> This source line, unlike the 2 above it, **doesn't** need to end with a pipe symbol. Most markdown formatting elements work correctly in tables, such as [links](https://example.com), *italic*, **bold**, and `inline code blocks`. Anything with multiple lines, such as fenced code blocks, probably won't work.

| :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------ |
| This Info block is less "shouty" than the WARNING, above. All the formatting and content notes in the WARNING example also apply here.
```

---

This renders as follows:

---

|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| This warning text must appear on a single line in the markdown source, as if there's a line break then the formatting will break. Whilst this can result in unwieldy source text, the rendered result looks fine. To force a line break, use an HTML `<br>` tag, like this:<br> To force a blank line use two, like this:<br><br> This source line, unlike the 2 above it, **doesn't** need to end with a pipe symbol. Most markdown formatting elements work correctly in tables, such as [links](https://example.com), *italic*, **bold**, and `inline code blocks`. Anything with multiple lines, such as fenced code blocks, probably won't work.

| :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------ |
| This Info block is less "shouty" than the WARNING, above. All the formatting and content notes in the WARNING example also apply here.
---
