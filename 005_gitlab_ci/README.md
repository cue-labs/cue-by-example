# Driving GitLab CI/CD pipelines with CUE
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

This guide explains how to convert a GitLab CI/CD pipeline file from YAML to
CUE, check its contents are valid, and then use CUE's tooling layer to
regenerate YAML.

This is useful because it allows you to switch to CUE as a source of truth for
GitLab pipelines and perform client-side validation, without GitLab needing to
know you're managing your pipelines with CUE.

|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| This guide requires that you use `cue` version `v0.11.0-alpha.4` or later. **The process described below won't work with earlier versions**. Check the version of your `cue` command by running `cue version`, and [upgrade it](https://cuelang.org/dl) if needed.

## Prerequisites

- You have a GitLab pipeline file.
  - The example shown throughout this guide uses the pipeline file from a
    specific commit in the
    [`gitlab-org/gitlab` repository](https://gitlab.com/gitlab-org/gitlab/-/blob/3308936efcd70839cc61e0545dcb780756e4ec28/.gitlab-ci.yml)
    on gitlab.com, as linked from GitLab's
    [CI documentation pages](https://docs.gitlab.com/ee/ci/yaml/),
    but **you don't need to use that repository in any way**. It's used as the
    example in this guide only because it's a reasonably complex GitLab
    pipeline file.
- You have [`cue` installed](https://cuelang.org/docs/install/).
  - You must have version `v0.11.0-alpha.4` or later installed. Using an
    earlier version will cause certain commands in this guide to fail.
- You have [`git` installed](https://git-scm.com/downloads).
- You have [`curl` installed](https://curl.se/dlwiz/), or can fetch a remote
  file some other way.

## Steps

### Convert YAML pipeline to CUE

#### :arrow_right: Begin with a clean git state

Change directory into the root of the repository that contains your GitLab
pipeline file, and ensure you start this process with a clean git state, with
no modified files. For example:

:computer: `terminal`
```sh
cd gitlab # our example repository
git status # should report "working tree clean"
```

#### :arrow_right: Initialise a CUE module

Initialise a CUE module named after the organisation and repository you're
working with, but containing only lowercase letters and numbers. For example:

:computer: `terminal`
```sh
cue mod init gitlab.com/gitlab-org/gitlab
```

#### :arrow_right: Import YAML pipeline

Use `cue` to import your YAML pipeline file:

:computer: `terminal`
```sh
cue import .gitlab-ci.yml --with-context -p gitlab -f -l pipelines: \
  -l 'strings.TrimSuffix(path.Base(filename),path.Ext(filename))' -o gitlab-ci.cue
```

If your project uses a different name for your pipeline file then use that name
in the above command, and throughout this guide.

Check that a CUE file has been created from your pipeline file. For example:

:computer: `terminal`
```sh
ls {,.}*gitlab-ci*
```

Your output should look similar to this, with a matching YAML and CUE file:

```text
.gitlab-ci.yml
gitlab-ci.cue
```
Observe that your file has been imported into the `pipelines` struct at a
location derived from its original file name, by running:

:computer: `terminal`
```sh
head -9 gitlab-ci.cue
```

The output should reflect your pipeline. In our example:

```text
package gitlab

pipelines: ".gitlab-ci": {
	stages: [
		"sync",
		"preflight",
		"prepare",
		"build-images",
		"fixtures",
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

#### :arrow_right: Create a pipeline schema

Fetch a schema for GitLab pipelines, as defined by the GitLab project, and
place it in the `internal/ci/gitlab` directory:

:computer: `terminal`
```sh
curl -sSo internal/ci/gitlab/gitlab.cicd.pipeline.schema.json https://gitlab.com/gitlab-org/gitlab/-/raw/277c9f6b643c92d00101aca0f2b4b874a144f7c5/app/assets/javascripts/editor/schema/ci.json
```

We use a specific commit from the upstream repository to make sure that this
process is reproducible.

Convert the GitLab schema from JSON Schema to CUE:

:computer: `terminal`
```sh
cue import -p gitlab -l '#Pipeline:' \
  internal/ci/gitlab/gitlab.cicd.pipeline.schema.json
```

This command will create the file `internal/ci/gitlab/gitlab.cicd.pipeline.schema.cue`
in the `gitlab` package, with the contents of the upstream schema placed in the
field `#Pipeline`.

#### :arrow_right: Apply the schema

We need to tell CUE to apply the schema to the pipeline.

To do this we'll create a file at `internal/ci/gitlab/pipelines.cue` in our
example. However, if your earlier pipeline import *already* created a file with
that same path and name, then simply select a different CUE filename that
*doesn't* already exist.

Create the file in the `internal/ci/gitlab/` directory and add this CUE:

:floppy_disk: `internal/ci/gitlab/pipelines.cue`

```cue
package gitlab

// each member of the pipelines struct must be a valid #Pipeline
pipelines: [_]: #Pipeline
```

#### :arrow_right: Validate your pipelines

:computer: `terminal`
```sh
cue vet ./internal/ci/gitlab
```

If this command fails and produces any output, then CUE believes that at least
one of your pipelines isn't valid. You'll need to resolve this before
continuing, by updating your pipelines inside your new CUE files. If you're
having difficulty fixing them, please come and ask for help in the friendly CUE
[Slack workspace](https://cuelang.org/s/slack) or
[Discord server](https://cuelang.org/s/discord)!

### Generate YAML from CUE

#### :arrow_right: Create a CUE workflow command

Create a CUE file in `internal/ci/gitlab/` containing the following workflow command.
Adapt the element commented with `TODO`:

:floppy_disk: `internal/ci/gitlab/ci_tool.cue`
```cue
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

The `regenerate` workflow command will export your CUE-based pipeline back into its required YAML file,
on demand.

#### :arrow_right: Test the CUE workflow command

With the modified `ci_tool.cue` file in place, check that the `regenerate`
workflow command is available **from a shell sitting at the repository root**. For
example:

:computer: `terminal`
```sh
cd $(git rev-parse --show-toplevel) # make sure we're sitting at the repository root
cue help cmd regenerate ./internal/ci/gitlab   # the "./" prefix is required
```

The output of the `cue help` command **must** begin with the following:

```text
Regenerate pipeline files

Usage:
  cue cmd regenerate [flags]
```
|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| If you *don't* see the usage explanation for the `regenerate` workflow command (or if you receive an error message) then **either** your workflow command isn't set up as CUE requires, **or** you're running a CUE version older than `v0.11.0-alpha.4`. If you've [upgraded to at least that version](https://cuelang.org/dl) but the usage explanation still isn't being displayed then: (1) double check the contents of the `ci_tool.cue` file and the modifications you made to it; (2) make sure its location in the repository is precisely as given in this guide; (3) ensure the filename is *exactly* `ci_tool.cue`; (4) run `cue vet ./internal/ci/gitlab` and check that your pipelines actually validate successfully - in other words: were they truly valid before you even started this process? Lastly, make sure you've followed all the steps in this guide, and that you invoked the `cue help` command from the repository's root directory. If you get really stuck, please come and join [the CUE community](https://cuelang.org/community/) and ask for some help!

#### :arrow_right: Regenerate the YAML pipeline file

Run the `regenerate` workflow command to produce a YAML pipeline file from CUE. For
example:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/gitlab # the "./" prefix is required
```

#### :arrow_right: Audit changes to the YAML pipeline file

Check that your YAML pipeline file has a single *material* change from the
original:

:computer: `terminal`
```sh
git diff .gitlab-ci.yml
```

Your output should look similar to the following example:

```diff
diff --git a/.gitlab-ci.yml b/.gitlab-ci.yml
--- a/.gitlab-ci.yml
+++ b/.gitlab-ci.yml
@@ -1,3 +1,5 @@
+# Code generated by internal/ci/gitlab/ci_tool.cue; DO NOT EDIT.
+
 stages:
   - sync
   - preflight
```
The main change in each YAML file is the addition of a header that warns the
reader not to edit the file directly.

Your diff might also contain some YAML reformatting (with the number of leading
spaces having been changed in nested structures) but this won't make a
difference to the underlying meaning of the file.

Additionally, any comments in the original YAML file will now be found *only*
in the CUE source file - which is important as that's the only file that you'll
be manually changing, from now on.

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
certain types of mistake earlier than before, without waiting for the slow "git
add/commit/push; check if CI fails" cycle.

From now on, each time you make a change to a CUE pipeline file, immediately
regenerate the YAML files required by GitLab CI/CD, and commit your changes to
all the CUE and YAML files. For example:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/gitlab/ # the "./" prefix is required
git add .gitlab-ci.yml internal/ci/gitlab/
git commit -m "ci: added new release pipeline" # example message
```
