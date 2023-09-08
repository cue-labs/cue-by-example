# Validating Terraform plans
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

This
[CUE By Example](/README.md#cue-by-example)
contains two documents, each showing you how to validate the 
[JSON output form](https://developer.hashicorp.com/terraform/internals/json-format)
of `terraform plan`.

- Example 1: [a.md](a.md)
- Example 2: [b.md](b.md)

[Example 1](a.md) mirrors an
[Open Policy Agent tutorial](https://www.openpolicyagent.org/docs/latest/terraform/),
not only in terms of the checks it performs but also the CUE UI it presents to
the user. Presenting this UI leads to some less idiomatic CUE and `cue` CLI usage.

[Example 2](b.md) demonstrates using idiomatic CUE to assert a slightly
different set of policies from the first document.
