# Driving GitLab CI/CD pipelines with CUE
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

This guide explains how to convert a GitLab CI/CD pipeline file from YAML to
CUE, check its contents are valid, and then use CUE's tooling layer to
regenerate YAML.

This allows you to switch to CUE as a source of truth for GitLab pipelines and
perform client-side validation, without GitLab needing to know you're managing
your pipelines with CUE.

## Prerequisites

- You have
  [CUE installed](https://alpha.cuelang.org/docs/introduction/installation/)
  locally. This allows you to run `cue` commands.
- You have a GitLab pipeline file. The example shown in this guide uses the
  state of a specific commit from the
  [Flockademic repository](https://gitlab.com/Flockademic/Flockademic/-/blob/8efcea927b10c2773790fe78bb858905a75cf3ef/.gitlab-ci.yml)
  on gitlab.com, but you don't need to use that repository in any way.
- You have [`git` installed](https://git-scm.com/downloads).
- You have [`curl` installed](https://curl.se/dlwiz/), or can fetch a file from
  a website some other way.

## Steps

### Convert YAML pipeline to CUE

#### :arrow_right: Begin with a clean git state

Change directory into the root of the repository that contains your GitLab
pipeline file, and ensure you start this process with a clean git state, with
no modified files. For example:

:computer: `terminal`
```sh
cd Flockademic   # our example repository
git status       # should report "working tree clean"
```

#### :arrow_right: Initialise a CUE module

Initialise a CUE module named after the organisation and repository you're
working with. For example:

:computer: `terminal`
```sh
cue mod init gitlab.com/Flockademic/Flockademic
```

#### :arrow_right: Import YAML pipeline

Use `cue` to import your YAML pipeline file:

:computer: `terminal`
```sh
cue import .gitlab-ci.yml --with-context -p gitlab -f -l pipelines: -l 'strings.TrimSuffix(path.Base(filename),path.Ext(filename))' -o gitlab-ci.cue
```

If your project uses a different name for your pipeline file, use that name in
the above command and throughout this guide.

Check that a CUE file has been created from your pipeline file. For example:

:computer: `terminal`
```sh
ls -l *gitlab-ci.*
```

Your output should look similar to this, with a matching YAML and CUE file:

```text
gitlab-ci.cue  .gitlab-ci.yml
```

Observe that your file has been imported into the `pipelines` struct, at a
location derived from its original file name:

:computer: `terminal`
```sh
head gitlab-ci.cue
```

The output should reflect your pipeline. In our example:

```text
package gitlab
pipelines: ".gitlab-ci": {
	image: "node:8.10"

	stages: [
		"prepare",
		"test",
		"build-backend",
		"deploy-backend",
```

#### :arrow_right: Store CUE pipelines in a dedicated directory

Create a directory called `gitlab` to hold your CUE-based GitLab pipeline
files. For example:

:computer: `terminal`
```sh
mkdir -p internal/ci/gitlab
```

You may change the hierarchy and naming of `gitlab`'s **parent** directories to
suit your repository layout. If you do so, you will need to adapt some commands
and CUE code as you follow this guide.

Move the newly-created CUE pipeline file into its dedicated directory. For example:

:computer: `terminal`
```sh
mv gitlab-ci.cue internal/ci/gitlab
```

### Validate pipeline

#### :arrow_right: Fetch a pipeline schema

<!--

### FIXME: The upstream schema isn't importable at the moment. ###

Fetch a schema for GitLab pipelines, as defined by the GitLab project, and
place it in the `internal/ci/gitlab` directory:

:computer: `terminal`
```sh
curl -o internal/ci/gitlab/gitlab.cicd.pipeline.schema.json https://gitlab.com/gitlab-org/gitlab/-/raw/d86a7ccc6233aaaf61d9721a537098c3e47fa7c5/app/assets/javascripts/editor/schema/ci.json
```

We use a specific commit from the upstream repository to make sure that this
process is reproducible.

-->

Create a CUE schema for GitLab pipelines, adapted from [GitLab CI/CD
documentation](https://docs.gitlab.com/ee/ci/yaml/index.html), and place it in
the `internal/ci/gitlab` directory:

:floppy_disk: `internal/ci/gitlab/gitlab.cicd.pipeline.schema.cue`

```CUE
package gitlab

_#globalKeyword: "default" | "include" | "stages" | "variables" | "workflow"
_#job:           _
#Pipeline: {
	default?: {
		after_script?:  _
		artifacts?:     _
		before_script?: _
		cache?:         _
		hooks?:         _
		id_tokens?:     _
		image?:         _
		interruptible?: _
		retry?:         _
		services?:      _
		tags?:          _
		timeout?:       _
	}
	include?: _
	stages?: [...string]
	variables?: _
	workflow?:  _

	[!_#globalKeyword]: _#job
}
```

<!-- FIXME: import isn't needed until the upstream JSONSchema is used

#### :arrow_right: Import the schema

Import the schema into CUE:

:computer: `terminal`
```sh
cue import -f -l '#Pipeline:' internal/ci/gitlab/gitlab.cicd.schema.json
```
-->

#### :arrow_right: Apply the schema

We need to tell CUE to apply the schema to the pipeline.

To do this we'll create a file at `internal/ci/gitlab/pipelines.cue` in our
example.

However, if the pipeline import that you performed earlier *already* created a
file with that same path and name, then simply select a different CUE filename
that *doesn't* already exist. Place the file in the `internal/ci/gitlab/`
directory.

:floppy_disk: `internal/ci/gitlab/pipelines.cue`

```
package gitlab

// each member of the pipelines struct must be a valid #Pipeline
pipeline: [_]: #Pipeline
```

### Generate YAML from CUE

#### :arrow_right: Create a CUE tool file

Create a CUE "tool" file at `internal/ci/gitlab/ci_tool.cue` and adapt the
element commented with `TODO`: FIXME: untested script

:floppy_disk: `internal/ci/gitlab/ci_tool.cue`
```CUE
package gitlab

import (
	"path"
	"encoding/yaml"
	"tool/file"
)

_goos: string @tag(os,var=os)

// Regenerate pipeline files
command: regenerate: {
	pipeline_files: {
		// TODO: update _toolFile to reflect the directory hierarchy containing this file.
		// TODO: update _pipelineDir to reflect the directory containing your pipeline file.
		let _toolFile = "internal/ci/gitlab/ci_tool.cue"
		let _pipelineDir = path.FromSlash(".", path.Unix)
		let _donotedit = "Code generated by \(_toolFile); DO NOT EDIT."

		for _pipelineName, _pipelineConfig in pipelines
		let _pipelineFile = _pipelineName + ".yml"
		let _pipelinePath = path.Join([_pipelineDir, _pipelineFile]) {
			let delete = {
				"Delete \(_pipelinePath)": file.RemoveAll & {path: _pipelinePath}
			}
			delete
			create: file.Create & {
				$after:   delete
				filename: _pipelinePath
				contents: "# \(_donotedit)\n\n\(yaml.Marshal(_pipelineConfig))"
			}
		}
	}
}
```

Make the modifications indicated by the `TODO` comments.

This tool will export your CUE-based pipeline back into its required YAML file,
on demand.

#### :arrow_right: Test the CUE tool file

With the modified `ci_tool.cue` file in place, check that the `regenerate`
command is available **from a shell sitting at the repo root**. For example:

:computer: `terminal`
```sh
cd $(git rev-parse --show-toplevel)            # make sure we're sitting at the repository root
cue help cmd regenerate ./internal/ci/gitlab   # the "./" prefix is required
```

Your output **must** begin with the following:

```text
Regenerate all pipeline files
Usage:
  cue cmd regenerate [flags]
[... output continues ...]
```

|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| If you *don't* see the usage explanation for the `regenerate` command (or if you receive an error message) then your tool file isn't set up as CUE requires. Double check the contents of the `ci_tool.cue` file and the modifications you made to it, as well as its location in the repository. Ensure the filename is *exactly* `ci_tool.cue`. Make sure you've followed all the steps in this guide, and that you invoked the `cue help` command from the root of the repository.

#### :arrow_right: Regenerate the YAML pipeline file

Run the `regenerate` command to produce a YAML pipeline file from CUE. For
example:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/gitlab   # the "./" prefix is required
```

#### :arrow_right: Audit changes to the YAML pipeline file

Check that your YAML pipeline file has a single change from the original:

:computer: `terminal`
```sh
git diff .gitlab-ci.yml
```

Your output should look similar to the following example:

```diff
FIXME
```

The only change in each YAML file is the addition of a header that warns the
reader not to edit the file directly.

#### :arrow_right: Add and commit files to git

Add your files to git. For example:

:computer: `terminal`
```sh
git add .gitlab-ci.yml internal/ci/gitlab/ cue.mod/module.cue
```

Make sure to include your slightly modified YAML pipeline file, wherever you
store it, along with all the new files in `internal/ci/gitlab/` and your
`cue.mod/module.cue` file.

Commit your files to git, with an appropriate commit message:

:computer: `terminal`
```sh
git commit -m "ci: create CUE sources for GitLab CI/CD pipelines"
```

## Conclusion

**Well done - your GitLab CI/CD pipeline file has been imported into CUE!**

It can now be managed using CUE, leading to safer and more predictable changes.
The use of a schema to check your pipeline means that you will catch and fix
many types of mistake earlier than before, without waiting for the slow "git
add/commit/push; check if CI fails" cycle.

From now on, each time you make a change to a CUE pipeline file, immediately
regenerate the YAML files required by GitLab CI/CD, and commit your changes to
all the CUE and YAML files. For example:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/gitlab/         # the "./" prefix is required
git add .gitlab-ci.yml internal/ci/gitlab/
git commit -m "ci: added new release pipeline"   # example message
```
