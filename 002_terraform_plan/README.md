# Validating Terraform plans
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

This guide focuses on how to validate the [JSON output
form](https://developer.hashicorp.com/terraform/internals/json-format) of
`terraform plan` using CUE as a policy language.

There are two variants of the guide:

- [Variant 1](a.md): is a CUE translation of an existing [Open Policy Agent
  tutorial](https://www.openpolicyagent.org/docs/latest/terraform/). This
  results in some un-idiomatic CUE and `cue` CLI usage.
- [Variant 2](b.md): uses more idiomatic CUE to assert a slightly different set
  of policies from the first variant.
