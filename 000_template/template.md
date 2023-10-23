# Writing cue-by-example guides
<sup>by [Jonathan Matthews](https://jonathanmatthews.com/)</sup>
<sup>and [Paul Jolly](https://myitcv.io/)</sup>

Use this file as a template when creating new cue-by-example guides.

## Introduction

This introduction explains the broad context of this guide, what technologies
it deals with, and what prerequisites the reader must be aware of to use the
guide successfully.

### Prerequisites

To use this guide, you need to:

- [install the `cue` command](https://alpha.cuelang.org/docs/introduction/installation/)
- and perhaps do some other things, as well

## Scenario A-1

This scenario can be read in isolation from any other scenario.

| :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------ |
| A scenario can build on the learnings imparted by other scenarios.<br><br>However, if its steps *cannot* be carried out without first completing another scenario, then consider merging the two scenarios into one.

### Create some files

This section is a container for the following 2 steps.

#### :arrow_right: Create `cue_file_1.cue`

:floppy_disk: `cue_file_1.cue`
```CUE
package foo

some_content: "some string"
some_boolean: true
```

#### :arrow_right: Create `really_long_file.txt`

<hr>
<details>
<summary>
:floppy_disk: <code>really_long_file.txt</code> (click to open)
</summary>

```text
A
long
file
but not
really long.
```
</details>
<hr>

### Do something with the files

#### :arrow_right: Audit the files

Count the lines in each file by running:

:computer: `terminal`
```sh
wc -l *
```

Expected output:
```
 4 cue_file_1.cue
 5 really_long_file.txt
 9 total
```

| :exclamation: WARNING :exclamation: |
|:----------------------------------- |
| The file `really_long_file.txt` is not, in fact, really long. This is a known weakness of [this guide](template.md).<br><br>Please feel free to open [an issue](/issues/new/choose) to track this problem.

## Scenario B-2

This is a very short scenario, which can be read separately from
[Scenario A-1](#scenario-a-1).

## Conclusion

This section concludes the guide by:

- reminding the reader about the significant elements of what they've achieved
  in the guide's different scenarios,
- reminding the reader why the scenarios' outcomes were useful,
- reenforcing any important reminders or warnings, and
- pointing to any additional guides or sites that might be useful to develop
  the reader's learning further.
