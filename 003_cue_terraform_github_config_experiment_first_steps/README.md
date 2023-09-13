# First steps with the cue-terraform-github-config-experiment repo
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)

## Introduction

This guide takes you through your first steps with the
<https://github.com/cue-examples/cue-terraform-github-config-experiment/>
repository. That repository is an experiment that demonstrates managing GitHub
entities (such as Organisations, Repositories, and Members) with CUE as the
source of truth, using Hashicorp's Terraform to enact any changes,
orchestrated by GitHub Actions.

## What this guide contains

This is a step-by-step guide showing how to fork the experiment's repo and use
it to:

- bring a single GitHub Organisation (an "org") under the system's control
- create a team of org members who have write access to every Repository
  ("repo") managed by the system
- create a new repo
- add an outside collaborator with read access to the new repo
- bring an existing repo under the system's control

Be aware that the system *cannot* perform the following operations, as they
simply aren't options presented by the GitHub API that Terraform uses:

- creating new orgs
- creating new user accounts

# WARNING

|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| The operations that this system performs include those that can cause data loss and changes in information's public visiblity. The first time you follow this guide, use a GitHub org created explicitly for testing that contains only unimportant data.<br><br> The responsibility for the permissions granted to this system, and for the actions that you explicitly or implicitly intruct it to take, is yours and yours alone.

## Prerequisites

TODO:
- GitHub account

## Steps

### Set up to enable the rest of this guide

#### :arrow_right: Fork the repo
#### :arrow_right: Have a GitHub account
#### :arrow_right: Create a GitHub machine account
#### :arrow_right: Have a TFC org
#### :arrow_right: Set up CI
##### Create TFC workspace
##### Create envvars
###### TFC
###### GH API
##### Add envvars as repo secrets
#### :arrow_right: Anything else that's in ...

https://github.com/cue-examples/cue-terraform-github-config-experiment/blob/main/docs/customising-this-repo.md

### Bring a GitHub org under the system's control

Also: will create the "company" team.

#### :arrow_right: Create a test GitHub org
#### :arrow_right: Manually add the machine user as an org owner
##### Send invite
##### Accept invite
#### :arrow_right: Review in-repo org-level defaults
#### :arrow_right: config

https://github.com/cue-examples/cue-terraform-github-config-experiment/#configuration-4

#### :arrow_right: content change

https://github.com/cue-examples/cue-terraform-github-config-experiment/#making-a-content-change-in-one-or-more-orgs

### Create a new repo

https://github.com/cue-examples/cue-terraform-github-config-experiment/#creating-a-new-repo

#### :arrow_right: Config

https://github.com/cue-examples/cue-terraform-github-config-experiment/#configuration

#### :arrow_right: content change

https://github.com/cue-examples/cue-terraform-github-config-experiment/#making-a-content-change-in-one-or-more-orgs

### Add an outside collaborator with read access to the new repo

#### :arrow_right: Config

TODO

#### :arrow_right: content change

https://github.com/cue-examples/cue-terraform-github-config-experiment/#making-a-content-change-in-one-or-more-orgs

### Bring an existing repo under the system's control

#### :arrow_right: Create fake "existing" repo via UI

#### :arrow_right: ALLLLL of the "managing existing resources" doc

https://github.com/cue-examples/cue-terraform-github-config-experiment/blob/main/docs/managing-existing-resources.md (304 rendered lines)

## Conclusion

## Next Steps
