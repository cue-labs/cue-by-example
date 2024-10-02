# Driving Buildkite Pipelines with CUE
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

This guide explains how to convert static Buildkite pipeline files from YAML to
CUE, check those pipelines are valid, and then use CUE's tooling layer to
regenerate YAML.

This allows you to switch to CUE as a source of truth for Buildkite pipelines
and perform client-side validation, without Buildkite needing to know you're
managing your static pipelines with CUE.

|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| This guide requires that you use `cue` version `v0.11.0-alpha.2` or later. **The process described below won't work with earlier versions**. Check the version of your `cue` command by running `cue version`, and [upgrade it](https://cuelang.org/dl) if needed.

## Prerequisites

- You have
  [CUE installed](https://alpha.cuelang.org/docs/introduction/installation/)
  locally. This allows you to run `cue` commands.
- You have a set of static Buildkite pipeline files. The examples shown in this
  guide use a specific commit from the Buildkite
  [dependent-pipeline-example](https://github.com/buildkite/dependent-pipeline-example/tree/a7419a24bee24068d4d79399bccd9093569c3013/.buildkite)
  repository, *but you don't need to use that repository in any way.*
- You have [`git` installed](https://git-scm.com/downloads).
<!-- TODO: curl isn't needed until the doc includes fetching the upstream schema
- You have [`curl` installed](https://curl.se/dlwiz/), or can fetch a file from
  a website some other way.
-->

## Steps

### Convert YAML pipelines to CUE

#### :arrow_right: Begin with a clean git state

Change directory into the root of the repository that contains your static
Buildkite pipeline files, and ensure you start this process with a clean git
state, with no modified files. For example:

:computer: `terminal`
```sh
cd dependent-pipeline-example # our example repository
git status                    # should report "working tree clean"
```

#### :arrow_right: Initialise a CUE module

Initialise a CUE module named after the organisation and repository you're
working with. For example:

:computer: `terminal`
```sh
cue mod init github.com/buildkite/dependent-pipeline-example
```

#### :arrow_right: Import YAML pipelines

Use `cue` to import your YAML pipeline files:

:computer: `terminal`
```sh
cue import ./.buildkite/*.yml --with-context -p buildkite -f -l pipelines: -l 'strings.TrimSuffix(path.Base(filename),path.Ext(filename))'
```

Check that a CUE file has been created for each YAML pipeline in the
`.buildkite` directory. For example:

:computer: `terminal`
```sh
ls .buildkite/
```

Your output should look similar to this, with matching pairs of pre-existing
YAML and new CUE files:

```text
pipeline.cue
pipeline.deploy.cue
pipeline.deploy.yml
pipeline.yml
```

Observe that each pipeline has been imported into the `pipelines` struct, at a
location derived from its original pipeline's file name:

:computer: `terminal`
```sh
head .buildkite/*.cue
```

The output should reflect your pipelines. In our example:

```text
==> .buildkite/pipeline.cue <==
package buildkite

pipelines: pipeline: steps: [{
	command: "echo 'Tests'"
	label:   ":hammer:"
},
	"wait", {
		trigger:  "dependent-pipeline-example-deploy"
		label:    ":rocket:"
		branches: "master"

==> .buildkite/pipeline.deploy.cue <==
package buildkite

pipelines: "pipeline.deploy": steps: [{
	command:           "echo 'Deploy'"
	label:             ":rocket:"
	concurrency_group: "$BUILDKITE_PIPELINE_SLUG-deploy"
	concurrency:       1
	branches:          "master"
}]
```

#### :arrow_right: Store CUE pipelines in a dedicated directory

Create a directory called `buildkite` to hold your CUE-based Buildkite pipeline
files. For example:

:computer: `terminal`
```sh
mkdir -p internal/ci/buildkite
```

You may change the hierarchy and naming of `buildkite`'s **parent** directories
to suit your repository layout. If you do so, you will need to adapt some
commands and CUE code as you follow this guide.

Move the newly-created CUE files into their dedicated directory. For example:

:computer: `terminal`
```sh
mv ./.buildkite/*.cue internal/ci/buildkite
```

### Validate workflows

<!-- TODO: upstream JSONSchema isn't usable
cf. https://github.com/cue-lang/cue/issues/2698
cf. https://github.com/cue-lang/cue/issues/2699

#### :arrow_right: Fetch a pipeline schema

Fetch a schema for Buildkite pipelines, as defined by Buildkite themselves, and
place it in the `internal/ci/buildkite` directory:

:computer: `terminal`
```sh
curl -o internal/ci/buildkite/buildkite.pipeline.schema.json https://raw.githubusercontent.com/buildkite/pipeline-schema/6396f68d5e983e0d2acbf829c565027a4cfd69bc/schema.json
```

We use a specific commit from the upstream repository to make sure that this
process is reproducible.

#### :arrow_right: Import the schema

Import the schema into CUE:

:computer: `terminal`
```sh
cue import -f -l '#Pipeline:' internal/ci/buildkite/buildkite.pipeline.schema.json
```
-->

#### :arrow_right: Create a pipeline schema

Create a very basic CUE schema for Buildkite pipelines, adapted from
[Buildkite's documentation](https://buildkite.com/docs/pipelines/configuration-overview),
and place it in the `internal/ci/buildkite` directory:

:floppy_disk: `internal/ci/buildkite/pipelineSchema.cue`

```CUE
package buildkite

#Pipeline: {
	steps!: [...]
	env?: [string]: string
	agents?: {[string]: string} | [ ..._#kv]
	_#kv:    =~".+="
	notify?: [...]
}
```

|  :grey_exclamation: Info :grey_exclamation: |
|:------------------------------------------- |
| It would be great if we could use [Buildkite's authoritative pipeline schema](https://github.com/buildkite/pipeline-schema) here. Unfortunately, CUE's JSONSchema support can't currently import it. This is being tracked in CUE Issues [#2698](https://github.com/cue-lang/cue/issues/2698) and [#2699](https://github.com/cue-lang/cue/issues/2699), and this guide should be updated once the schema is useable.

#### :arrow_right: Apply the schema

We need to tell CUE to apply the schema to each pipeline.

To do this we'll create a file at `internal/ci/buildkite/pipelines.cue` in our
example.

However, **if the pipeline imports that you performed earlier *already* created
a file with that same path and name**, then simply select a different CUE
filename that *doesn't* already exist. Place the file in the
`internal/ci/buildkite/` directory.

:floppy_disk: `internal/ci/buildkite/pipelines.cue`

```
package buildkite

// each member of the pipelines struct must be a valid #Pipeline
pipelines: [_]: #Pipeline
```

### Generate YAML from CUE

We need to replace the static YAML pipeline files that we originally imported
with YAML generated from the CUE files we've created. No material changes will
be made to the YAML files, but comments will be removed (as they now live
in the CUE sources, where users will see them), some unimportant YAML
formatting may change, and a comment will be added at the top of each generated
YAML file pointing users towards the new source of truth: CUE.

#### :arrow_right: Create a CUE workflow command

Create a CUE file at `internal/ci/buildkite/ci_tool.cue` containing the following workflow command.
Adapt the element commented with `TODO`:

:floppy_disk: `internal/ci/buildkite/ci_tool.cue`
```CUE
package buildkite

import (
	"path"
	"encoding/yaml"
	"tool/file"
)

_goos: string @tag(os,var=os)

// Regenerate all pipeline files
command: regenerate: {
	pipeline_files: {
		// TODO: update _toolFile to reflect the directory hierarchy containing this file.
		let _toolFile = "internal/ci/buildkite/ci_tool.cue"
		let _pipelineDir = path.FromSlash(".buildkite", path.Unix)
		let _donotedit = "Code generated by \(_toolFile); DO NOT EDIT."

		clean: {
			glob: file.Glob & {
				glob: path.Join([_pipelineDir, "*.yml"], _goos)
				files: [...string]
			}
			for _, _filename in glob.files {
				"Delete \(_filename)": file.RemoveAll & {path: _filename}
			}
		}

		create: {
			for _pipelineName, _pipeline in pipelines
			let _filename = _pipelineName + ".yml" {
				"Generate \(_filename)": file.Create & {
					$after: [ for v in clean {v}]
					filename: path.Join([_pipelineDir, _filename], _goos)
					contents: "# \(_donotedit)\n\n\(yaml.Marshal(_pipeline))"
				}
			}
		}
	}
}
```

Make the modification indicated by the `TODO` comment.

This workflow command will export each CUE-based pipeline back into its required YAML file,
on demand.

#### :arrow_right: Test the CUE workflow command

With the modified `ci_tool.cue` file in place, check that the `regenerate`
workflow command is available **from a shell sitting at the repo root**. For example:

:computer: `terminal`
```sh
cd $(git rev-parse --show-toplevel)               # make sure we're sitting at the repository root
cue help cmd regenerate ./internal/ci/buildkite   # the "./" prefix is required
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
| If you *don't* see the usage explanation for the `regenerate` workflow command (or if you receive an error message) then **either** your workflow command isn't set up as CUE requires, **or** you're running a CUE version older than `v0.11.0-alpha.2`. If you've [upgraded to at least that version](https://cuelang.org/dl) but the usage explanation still isn't being displayed then: (1) double check the contents of the `ci_tool.cue` file and the modifications you made to it; (2) make sure its location in the repository is precisely as given in this guide; (3) ensure the filename is *exactly* `ci_tool.cue`; (4) run `cue vet ./internal/ci/buildkite` and check that your pipelines actually validate successfully - in other words: were they truly valid before you even started this process? Lastly, make sure you've followed all the steps in this guide, and that you invoked the `cue help` command from the repository's root directory. If you get really stuck, please come and join [the CUE community](https://cuelang.org/community/) and ask for some help!

#### :arrow_right: Regenerate the YAML pipeline files

Run the `regenerate` workflow command to produce YAML pipeline files from CUE. For
example:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/buildkite   # the "./" prefix is required
```

#### :arrow_right: Audit changes to the YAML pipeline files

Check that each YAML pipeline file has a single *material* change from the
original:

:computer: `terminal`
```sh
git diff .buildkite/
```

Your output should look similar to the following example:

```diff
diff --git a/.buildkite/pipeline.deploy.yml b/.buildkite/pipeline.deploy.yml
index 4af2b9d..e0fc010 100644
--- a/.buildkite/pipeline.deploy.yml
+++ b/.buildkite/pipeline.deploy.yml
@@ -1,6 +1,8 @@
+# Code generated by internal/ci/buildkite/ci_tool.cue; DO NOT EDIT.
+
 steps:
   - command: echo 'Deploy'
diff --git a/.buildkite/pipeline.yml b/.buildkite/pipeline.yml
index 7446201..10cefad 100644
--- a/.buildkite/pipeline.yml
+++ b/.buildkite/pipeline.yml
@@ -1,12 +1,14 @@
+# Code generated by internal/ci/buildkite/ci_tool.cue; DO NOT EDIT.
+
 steps:
   - command: echo 'Tests'
     label: ':hammer:'
   - wait
   - trigger: dependent-pipeline-example-deploy
```

The only *material* change in each YAML file is the addition of a header that
warns the reader not to edit the file directly.

#### :arrow_right: Add and commit files to git

Add your files to git. For example:

:computer: `terminal`
```sh
git add .buildkite/ internal/ci/buildkite/ cue.mod/module.cue
```

Make sure to include your slightly modified YAML pipeline files in
`.buildkite/` along with all the new files in `internal/ci/buildkite/` and
your `cue.mod/module.cue` file.

Commit your files to git, with an appropriate commit message:

:computer: `terminal`
```sh
git commit -m "ci: create CUE sources for Buildkite pipelines"
```

## Conclusion

**Well done - your static Buildkite pipeline files have been imported into
CUE!**

They can now be managed using CUE, leading to safer and more predictable
changes. The use of a schema to check your pipelines means that you
will catch and fix many types of mistake earlier than before, without waiting
for the slow "git add/commit/push; check if CI fails" cycle.

From now on, each time you make a change to a CUE pipeline file, immediately
regenerate the YAML files required by Buildkite, and commit your changes
to all the CUE and YAML files. For example:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/buildkite/      # the "./" prefix is required
git add .buildkite/ internal/ci/buildkite/
git commit -m "ci: added new release pipeline"   # example message
```
