# Supercharging Buildkite dynamic pipelines with CUE
<sup>by [Jonathan Matthews](https://jonathanmatthews.com/)</sup>

This guide demonstrates how to use CUE to generate dynamic pipelines for the
Bring-Your-Own-Compute CI service [Buildkite](https://buildkite.com).

This guide should be read alongside Buildkite's blog post
"[The power of Dynamic Pipelines](https://buildkite.com/blog/how-to-build-ci-cd-pipelines-dynamically)",
as this guide builds on the setup described in the blog post.

Start by reading this guide's [introduction](#introduction) section.

## Introduction

Buildkite offers a way to define CI pipelines as they're initiated and as
they're executing, which allows the pipeline's steps to be varied dynamically.
This allows the process that emits the specific pipeline steps to take the
pipeline's execution context into account.

For example: the Buildkite blog post contains a setup guide (that you'll follow
shortly) which finishes by creating a dynamic pipeline that includes a deploy
step *only if it's the master branch*.

Using **this** guide, you'll first follow the Buildkite blog post's instructions
until the dynamic pipeline needs to be created, and then switch back to this
guide to create the pipeline using CUE.

### Prerequisites

To use this guide, first make sure that:

- you have
  [CUE installed](https://alpha.cuelang.org/docs/introduction/installation/)
  locally. This allows you to run `cue` commands
- you have
  [`git` installed](https://git-scm.com/downloads)
  locally. This allow you to make changes to your fork of the Buildkite example
  repository
- you have access to a git hosting account. It's probably easiest to use a
  GitHub account, but any publically accessible git service will work
- you have access to a Buildkite account. If you don't, the Buildkite blog post
  shows you where to sign up for their Free plan

## Start here

Begin by reading
[the Buildkite blog post on dynamic pipelines](https://buildkite.com/blog/how-to-build-ci-cd-pipelines-dynamically)
and follow its instructions *up to but not including* the section titled
"Including custom steps". **The blog post gives you a choice of a Bash or
a Powershell example project: please select the Bash example.**

When you reach the blog post's sentence `We don’t yet have a "dynamic" build
pipeline, or a pipeline that runs a script`, switch back to this guide and
continue reading from here.

| :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------ |
| If you want to start with one of your own pipelines, and not the pipeline created by following the Buildkite blog post's instructions, then that's fine. Make sure that your pipeline starts in a green state, and you have the ability to change the underlying git repository's contents. You'll have to make adjustments as you follow this guide to adapt its steps to the specifics of your pipeline and repository layout. Continue following this guide at the "[Add some files to the repository](#add-some-files-to-the-repository)" step.

## Continue here after reading the Buildkite blog post

By following the Buildkite blog post's instructions before this section, you
have successfully executed a static example pipeline and are now ready to make
the pipeline dynamic.

### Prepare to make changes to the pipeline's contents

#### :arrow_right: Fork the Buildkite example repository

As part of the blog post's instructions, you created a pipeline using the
Buildkite
[bash-example repository](https://github.com/buildkite/bash-example.git).

Fork that repository under your own git hosting account and clone the forked
repository onto your local machine, so that you can make changes to its
contents. In this guide, all references to "repository" refer to your forked
repository from this point on.

#### :arrow_right: Update the pipeline to reference your repository

In the Buildkite web UI, find the settings page for the pipeline you created.
Open the "GitHub" settings tab.

In the "Repository Settings" section, change the "Repository" field so that it
contains the cloneable URL of your forked repository. Save the setting.

#### :arrow_right: Test the pipeline's new settings

In the Buildkite web UI, create a new build for the pipeline. Check that it
still completes successfully, and goes green.

If the updated pipeline doesn't go green you'll need to diagnose and fix this
before continuing.

### Add some files to the repository

#### :arrow_right: Create a location for your CUE files

At the top-level of your repository, create a directory to hold your Buildkite
CUE files:

:computer: `terminal`
```sh
cd $(git rev-parse --show-toplevel)   # make sure we're sitting at the repository root
mkdir -p internal/ci/buildkite/
```

| :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------ |
| You *can* change the `buildkite` directory's *location*, but **don't change its name**.<br>If you change its location, you'll have to adapt some commands to match the new location, as you follow the rest of this guide.

#### :arrow_right: Create dynamic steps

:floppy_disk: `internal/ci/buildkite/dynamicSteps.cue`
```CUE
package pipeline

// env contains all environment variables that are present when `cue` is
// invoked. If a default value is set (with a "*" prefix) then that value will
// apply only when the associated environment variable *isn't* defined.
// Setting a default value allows testing to be performed outside a Buildkite
// context - i.e. before a change is pushed to the repository.
env: {
	BUILDKITE_AGENT_ENDPOINT: *"test value" | _
	BUILDKITE_BRANCH:         *"test value" | _
}

// dynamic_steps contains an ordered list of the steps which will be appended
// to the pipeline's initial definition.
dynamic_steps: [
	{command: "echo dynamic step 1"},
	{command: "echo dynamic step 2"},
	{command: "echo The agent endpoint in use is \(ENV.BUILDKITE_AGENT_ENDPOINT)"},
	{command: "echo dynamic step 3"},
	if ENV.BUILDKITE_BRANCH == "main" {"wait"},
	if ENV.BUILDKITE_BRANCH == "main" {
		{
			command: "echo Deploy!"
			label:   ":rocket:"
		}
	},
]
```

These steps are (of course!) just examples. Replace them with steps that meet
your pipeline's requirements. You can use any CUE features and structure,
including using the contents of the context-specific `env` struct
conditionally, as demonstrated above, so long as the `dynamic_steps` field
ultimately contains an ordered list of the steps your pipeline needs to
execute.

#### :arrow_right: Create a CUE workflow command

:floppy_disk: `internal/ci/buildkite/dynamic_tool.cue`
```CUE
package pipeline

import (
	"encoding/yaml"
	"tool/os"
	"tool/cli"
)

env: command.emit_dynamic_steps.envvars
dynamic_steps: [...]

command: emit_dynamic_steps: {
	envvars: os.Environ
	emit:    cli.Print & {
		text: yaml.Marshal({steps: dynamic_steps})
	}
}
```

#### :arrow_right: Create CUE schema

:floppy_disk: `internal/ci/buildkite/dynamicSchema.cue`
```CUE
package pipeline

ENV: close({[string]: string})
#Step: _
dynamic_steps: [...#Step]
```

|  :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------- |
| It would be great if we could use [Buildkite's authoritative pipeline schema](https://github.com/buildkite/pipeline-schema) here. Unfortunately, CUE's JSONSchema support can't currently import it. This is being tracked in CUE Issues [#2698](https://github.com/cue-lang/cue/issues/2698) and [#2699](https://github.com/cue-lang/cue/issues/2699), and this guide should be updated once the schema is useable.

#### :arrow_right: Create CUE policy

Create a CUE policy file that makes sure that *future* changes to the pipeline
also adhere to the policy.

Here, as an example, we only allow the "main", "staging" and "qa" branches to
contain command steps that trigger a deployment.

:floppy_disk: `internal/ci/buildkite/dynamicPolicy.cue`
```CUE
package pipeline

import "encoding/json"

ENV: _

#branchesPermittedToDeploy: "main" | "staging" | "qa"

// if the branch driving the pipeline *isn't* contained in
// #branchesPermittedToDeploy then we insist that all members of
// `dynamic_steps` that contain commands *don't* include the word "Deploy"
// in their command string.
#noDeploys: {command?: !~"Deploy", ...} | [...] | string | number | bytes
if json.Marshal(ENV.BUILDKITE_BRANCH & #branchesPermittedToDeploy) == _|_ {
	dynamic_steps?: [...#noDeploys]
}
```

**You will need to change this policy to match your pipeline requirements** (or
remove it entirely) before using this pipeline on a real project!

### Update the pipeline to use CUE

#### :arrow_right: Install CUE on the Buildkite agent's machine

*This guide doesn't yet extend as far as exposing CUE as a Buildkite plugin, or
installing it at the start of each pipeline run. Instead, it currently assumes
that the `cue` binary is available on each machine that runs the Buildkite
agent.*

[Install CUE](https://alpha.cuelang.org/docs/introduction/installation/) on
each machine that runs the Buildkite agent and which might pick up this
pipeline's jobs. Make sure `cue` is available in the Buildkite agent's `PATH`.

#### :arrow_right: Update the pipeline's definition

In the Buildkite web UI, update the pipeline's settings so that its first step
runs this CUE workflow command:

```
cue cmd emit_dynamic_steps ./internal/ci/buildkite:pipeline | buildkite-agent pipeline upload
```

If you followed the Buildkite blog post's instructions, then your pipeline will
probably have been created in Buildkite's "Legacy Steps" mode. If so, use the
web UI's editor to change the "Commands to run" field to:

```
cue cmd emit_dynamic_steps ./internal/ci/buildkite:pipeline | buildkite-agent pipeline upload
```

Alternatively, if your pipeline is set up in Buildkite's "YAML Steps" mode, you
can place the following in the web UI's "Steps" YAML editor pane, overwriting
the steps that are already there:

```yaml
steps:
- command: cue cmd emit_dynamic_steps ./internal/ci/buildkite:pipeline | buildkite-agent pipeline upload
```

| :exclamation: WARNING :exclamation: |
|:----------------------------------- |
If you are adapting an existing, working, pipeline, there may already be additional YAML keys present other than `steps`.<br>**Do not change these**.

#### :arrow_right: Publish your changes

Use `git` to commit and push the files you've added to the repository.
For example:

:computer: `terminal`
```sh
git add internal/ci/buildkite
git commit -m "ci: make pipeline dynamic with CUE"
git push
```

#### :arrow_right: Test your new pipeline

In the Buildkite web UI, create a new build for the pipeline. Check that it
still completes successfully, and goes green.

If it doesn't go green, double-check that you copied and set the initial
pipeline command correctly, in this guide's
"[Update the pipeline's definition](#arrow_right-update-the-pipelines-definition)"
step.

You can also use the following workflow command in your local checkout of the
repository. It displays the contents of the steps which will be passed back to
Buildkite for execution:

:computer: `terminal`
```sh
cue cmd emit_dynamic_steps ./internal/ci/buildkite:pipeline
```

If your CUE is using any of
[Buildkite's environment variables](https://buildkite.com/docs/pipelines/environment-variables#buildkite-environment-variables)
to make build-context-dependent decisions about the steps to output then you
can set the variables locally, as shown in this example:

:computer: `terminal`
```sh
BUILDKITE_BRANCH="main" cue cmd emit_dynamic_steps ./internal/ci/buildkite:pipeline
```

## Conclusion

Congratulations! You've converted a Buildkite pipeline from being static to
being defined and driven by CUE - potentially using information that's only
available at the time of execution to build the pipeline dynamically.

Your use of CUE will increase the safety with which you make pipeline changes,
by providing a scalable and effective framework for managing complex pipelines.
