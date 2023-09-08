# Validating Terraform plan output
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

This document is an adaptation of an
[OPA Terraform tutorial](https://www.openpolicyagent.org/docs/latest/terraform/)
into CUE.

It contains 2 scenarios, each of which guides you through checking that
specific Terraform input files translate into acceptable Terraform actions, as
exposed via
[Terraform's plan format](https://developer.hashicorp.com/terraform/internals/json-format#plan-representation)

## Prerequisites

Before following either scenario in this tutorial, please make sure:

- you have
  [CUE installed](https://alpha.cuelang.org/docs/introduction/installation/)
  locally
- you have
  [Terraform installed](https://developer.hashicorp.com/terraform/downloads)
  locally
- you have set up your
  [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
  correctly for your terminal to use
  - a good litmus test is "does running `aws sts get-caller-identity` report
    success or failure?", but having the `aws` CLI tool installed is *not*
    required to follow this document

## Scenario 1: A plan that doesn't use Terraform modules

### Steps

#### :arrow_right: Create a Terraform input file

:floppy_disk: `main.tf`
```hcl
provider "aws" {
    region = "us-west-1"
}
resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami = "ami-09b4b74c"
}
resource "aws_autoscaling_group" "my_asg" {
  availability_zones        = ["us-west-1a"]
  name                      = "my_asg"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  launch_configuration      = "my_web_config"
}
resource "aws_launch_configuration" "my_web_config" {
    name = "my_web_config"
    image_id = "ami-09b4b74c"
    instance_type = "t2.micro"
}
```

#### :arrow_right: Create a Terraform plan

Make Terraform save a plan in `tfplan.binary`, containing the set of changes
it's proposing:

:computer: `terminal`
```sh
terraform init
terraform plan --out tfplan.binary
```

#### :arrow_right: Convert the plan into JSON

Convert the Terraform plan into its JSON form, using `cue export` to format the
plan into a readable form:

:computer: `terminal`
```sh
terraform show -json tfplan.binary | cue export json: - -o tfplan.json
```

Check that the JSON form looks similar to the following:

---

<details>
<summary>
:floppy_disk: <code>tfplan.json</code> (click to expand large file)
</summary>

```json
{
  "format_version": "0.1",
  "terraform_version": "0.12.6",
  "planned_values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_autoscaling_group.my_asg",
          "mode": "managed",
          "type": "aws_autoscaling_group",
          "name": "my_asg",
          "provider_name": "aws",
          "schema_version": 0,
          "values": {
            "availability_zones": [
              "us-west-1a"
            ],
            "desired_capacity": 4,
            "enabled_metrics": null,
            "force_delete": true,
            "health_check_grace_period": 300,
            "health_check_type": "ELB",
            "initial_lifecycle_hook": [],
            "launch_configuration": "my_web_config",
            "launch_template": [],
            "max_size": 5,
            "metrics_granularity": "1Minute",
            "min_elb_capacity": null,
            "min_size": 1,
            "mixed_instances_policy": [],
            "name": "my_asg",
            "name_prefix": null,
            "placement_group": null,
            "protect_from_scale_in": false,
            "suspended_processes": null,
            "tag": [],
            "tags": null,
            "termination_policies": null,
            "timeouts": null,
            "wait_for_capacity_timeout": "10m",
            "wait_for_elb_capacity": null
          }
        },
        {
          "address": "aws_instance.web",
          "mode": "managed",
          "type": "aws_instance",
          "name": "web",
          "provider_name": "aws",
          "schema_version": 1,
          "values": {
            "ami": "ami-09b4b74c",
            "credit_specification": [],
            "disable_api_termination": null,
            "ebs_optimized": null,
            "get_password_data": false,
            "iam_instance_profile": null,
            "instance_initiated_shutdown_behavior": null,
            "instance_type": "t2.micro",
            "monitoring": null,
            "source_dest_check": true,
            "tags": null,
            "timeouts": null,
            "user_data": null,
            "user_data_base64": null
          }
        },
        {
          "address": "aws_launch_configuration.my_web_config",
          "mode": "managed",
          "type": "aws_launch_configuration",
          "name": "my_web_config",
          "provider_name": "aws",
          "schema_version": 0,
          "values": {
            "associate_public_ip_address": false,
            "enable_monitoring": true,
            "ephemeral_block_device": [],
            "iam_instance_profile": null,
            "image_id": "ami-09b4b74c",
            "instance_type": "t2.micro",
            "name": "my_web_config",
            "name_prefix": null,
            "placement_tenancy": null,
            "security_groups": null,
            "spot_price": null,
            "user_data": null,
            "user_data_base64": null,
            "vpc_classic_link_id": null,
            "vpc_classic_link_security_groups": null
          }
        }
      ]
    }
  },
  "resource_changes": [
    {
      "address": "aws_autoscaling_group.my_asg",
      "mode": "managed",
      "type": "aws_autoscaling_group",
      "name": "my_asg",
      "provider_name": "aws",
      "change": {
        "actions": [
          "create"
        ],
        "before": null,
        "after": {
          "availability_zones": [
            "us-west-1a"
          ],
          "desired_capacity": 4,
          "enabled_metrics": null,
          "force_delete": true,
          "health_check_grace_period": 300,
          "health_check_type": "ELB",
          "initial_lifecycle_hook": [],
          "launch_configuration": "my_web_config",
          "launch_template": [],
          "max_size": 5,
          "metrics_granularity": "1Minute",
          "min_elb_capacity": null,
          "min_size": 1,
          "mixed_instances_policy": [],
          "name": "my_asg",
          "name_prefix": null,
          "placement_group": null,
          "protect_from_scale_in": false,
          "suspended_processes": null,
          "tag": [],
          "tags": null,
          "termination_policies": null,
          "timeouts": null,
          "wait_for_capacity_timeout": "10m",
          "wait_for_elb_capacity": null
        },
        "after_unknown": {
          "arn": true,
          "availability_zones": [
            false
          ],
          "default_cooldown": true,
          "id": true,
          "initial_lifecycle_hook": [],
          "launch_template": [],
          "load_balancers": true,
          "mixed_instances_policy": [],
          "service_linked_role_arn": true,
          "tag": [],
          "target_group_arns": true,
          "vpc_zone_identifier": true
        }
      }
    },
    {
      "address": "aws_instance.web",
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider_name": "aws",
      "change": {
        "actions": [
          "create"
        ],
        "before": null,
        "after": {
          "ami": "ami-09b4b74c",
          "credit_specification": [],
          "disable_api_termination": null,
          "ebs_optimized": null,
          "get_password_data": false,
          "iam_instance_profile": null,
          "instance_initiated_shutdown_behavior": null,
          "instance_type": "t2.micro",
          "monitoring": null,
          "source_dest_check": true,
          "tags": null,
          "timeouts": null,
          "user_data": null,
          "user_data_base64": null
        },
        "after_unknown": {
          "arn": true,
          "associate_public_ip_address": true,
          "availability_zone": true,
          "cpu_core_count": true,
          "cpu_threads_per_core": true,
          "credit_specification": [],
          "ebs_block_device": true,
          "ephemeral_block_device": true,
          "host_id": true,
          "id": true,
          "instance_state": true,
          "ipv6_address_count": true,
          "ipv6_addresses": true,
          "key_name": true,
          "network_interface": true,
          "network_interface_id": true,
          "password_data": true,
          "placement_group": true,
          "primary_network_interface_id": true,
          "private_dns": true,
          "private_ip": true,
          "public_dns": true,
          "public_ip": true,
          "root_block_device": true,
          "security_groups": true,
          "subnet_id": true,
          "tenancy": true,
          "volume_tags": true,
          "vpc_security_group_ids": true
        }
      }
    },
    {
      "address": "aws_launch_configuration.my_web_config",
      "mode": "managed",
      "type": "aws_launch_configuration",
      "name": "my_web_config",
      "provider_name": "aws",
      "change": {
        "actions": [
          "create"
        ],
        "before": null,
        "after": {
          "associate_public_ip_address": false,
          "enable_monitoring": true,
          "ephemeral_block_device": [],
          "iam_instance_profile": null,
          "image_id": "ami-09b4b74c",
          "instance_type": "t2.micro",
          "name": "my_web_config",
          "name_prefix": null,
          "placement_tenancy": null,
          "security_groups": null,
          "spot_price": null,
          "user_data": null,
          "user_data_base64": null,
          "vpc_classic_link_id": null,
          "vpc_classic_link_security_groups": null
        },
        "after_unknown": {
          "ebs_block_device": true,
          "ebs_optimized": true,
          "ephemeral_block_device": [],
          "id": true,
          "key_name": true,
          "root_block_device": true
        }
      }
    }
  ],
  "configuration": {
    "provider_config": {
      "aws": {
        "name": "aws",
        "expressions": {
          "region": {
            "constant_value": "us-west-1"
          }
        }
      }
    },
    "root_module": {
      "resources": [
        {
          "address": "aws_autoscaling_group.my_asg",
          "mode": "managed",
          "type": "aws_autoscaling_group",
          "name": "my_asg",
          "provider_config_key": "aws",
          "expressions": {
            "availability_zones": {
              "constant_value": [
                "us-west-1a"
              ]
            },
            "desired_capacity": {
              "constant_value": 4
            },
            "force_delete": {
              "constant_value": true
            },
            "health_check_grace_period": {
              "constant_value": 300
            },
            "health_check_type": {
              "constant_value": "ELB"
            },
            "launch_configuration": {
              "constant_value": "my_web_config"
            },
            "max_size": {
              "constant_value": 5
            },
            "min_size": {
              "constant_value": 1
            },
            "name": {
              "constant_value": "my_asg"
            }
          },
          "schema_version": 0
        },
        {
          "address": "aws_instance.web",
          "mode": "managed",
          "type": "aws_instance",
          "name": "web",
          "provider_config_key": "aws",
          "expressions": {
            "ami": {
              "constant_value": "ami-09b4b74c"
            },
            "instance_type": {
              "constant_value": "t2.micro"
            }
          },
          "schema_version": 1
        },
        {
          "address": "aws_launch_configuration.my_web_config",
          "mode": "managed",
          "type": "aws_launch_configuration",
          "name": "my_web_config",
          "provider_config_key": "aws",
          "expressions": {
            "image_id": {
              "constant_value": "ami-09b4b74c"
            },
            "instance_type": {
              "constant_value": "t2.micro"
            },
            "name": {
              "constant_value": "my_web_config"
            }
          },
          "schema_version": 0
        }
      ]
    }
  }
}
```
</details>

---

#### :arrow_right: Create a CUE policy file

:floppy_disk: `policy.cue`
```CUE
package policy

import "list"

// the teraform plan's json form,
// placed here via the `-l tfplan:` parameter
tfplan: _

// acceptable score for automated authorization,
// controllable via `-t blast_radius=`
blast_radius: {*30 | int} @tag(blast_radius,type=int)

// weights assigned for each operation on each resource-type
weights: aws_autoscaling_group: {
	"delete": 100
	"create": 10
	"modify": 1
}
weights: aws_instance: {
	"delete": 10
	"create": 1
	"modify": 1
}

// Consider only these resource types in score calculations
resource_types: [
	"aws_autoscaling_group",
	"aws_instance",
	"aws_iam",
	"aws_launch_configuration",
]

// authz: the final result of checking a plan against all policies
authz: bool
authz: ({for check, result in checks {result}} & true) != _|_

// checks: the boolean results of each individual policy
checks: [_]: bool
checks: {
	score_ok: score < blast_radius
	iam_ok:   no_iam_changes != _|_
}

// no_iam_changes attempts to unify the set of planned resource_changes with a
// policy that rejects all non-no-op aws_iam changes
no_iam_changes: tfplan.resource_changes
no_iam_changes: [...exclude_aws_iam]
exclude_aws_iam: {
	type: !="aws_iam"
} | {
	change: actions: ["no-op"]
}

// score embeds an integer representing the sum of all resource_changes in the
// plan, weighted by resource type and change type
score: {
	int & list.Sum(_by_resource)
	_by_resource: [
		for resource in tfplan.resource_changes
		if list.Contains(resource_types, resource.type)
		for action in resource.change.actions
		let resource_score = *weights[resource.type][action] | 0 {
			{resource_score}
		},
	]
}
```

The policy computes a score for a Terraform that combines:

- The number of deletions of each resource type
- The number of creations of each resource type
- The number of modifications of each resource type

The policy rejects any plan whose score is above a threshold (called the "blast
radius"), or if the plan proposes changes to any AWS IAM resources.

#### :arrow_right: Evaluate the Terraform plan against the CUE policy

Evaluate the policy with the default `blast_radius` setting:

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e authz
```

Expected output:
```text
true
```

Evaluate the policy whilst forcing the command to fail if the policy isn't
complied with (i.e. in a manner suitable for automated/scripted use):

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json  -e 'authz & true'
```

That command is expected to succeed, with the following output:

```text
true
```

Evaluate the policy with a more conservative `blast_radius` setting:

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e authz -t blast_radius=10
```

Expected output:
```text
false
```

Evaluate the policy against a `blast_radius` of 10, whilst forcing the command
to fail if the policy isn't complied with:

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e 'authz & true' -t blast_radius=10
```

That command is expected to fail, with following output:

```text
conflicting values true and false:
    --expression:1:1
    --expression:1:9
    ./policy.cue:35:8
```

Display which checks caused the lower `blast_radius` setting's policy failure:

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e '{check: checks}' -t blast_radius=10
```

Expected output:
```text
check: {
    score_ok: false
    iam_ok:   true
}
```

### Scenario summary

Congratulations - you've successfully checked that Terraform's proposed changes
met your policy requirements of making no IAM changes, and only small changes
elsewhere!

There are many different ways to write CUE to check Terraform plans, as CUE
only knows what you explicitly instruct it to test. The Terraform documentation
on each plan's
[JSON data format](https://developer.hashicorp.com/terraform/internals/) will
help you write policies for the specific situations you need to deal with.

## Scenario 2: A plan that uses a Terraform module

Plans that come from configurations that use Terraform modules have a more
complex structure. It requires a bit more work to assert policies against their
contents.

The following example uses the 3rd-party module published at
<https://github.com/terraform-aws-modules/terraform-aws-security-group>.
Terraform will install the module automatically.

### Steps

#### :arrow_right: Create a Terraform input file

*Replace* the `main.tf` file you used above with the following configuration
that includes a security group and security group defined by the 3rd-party
module.

:floppy_disk: `main.tf`
```hcl
provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

module "http_sg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.1.0"

  name        = "http-sg"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
```

#### :arrow_right: Create a Terraform plan

Make Terraform save a plan in `tfplan.binary`, containing the set of changes
it's proposing:

:computer: `terminal`
```sh
terraform init
terraform plan --out tfplan.binary
```

#### :arrow_right: Convert the plan into JSON

Convert the Terraform plan into its JSON form, using `cue export` to format the
plan into a readable form:

:computer: `terminal`
```sh
terraform show -json tfplan.binary | cue export json: - -o tfplan.json
```

Check that the JSON file looks similar to the following **truncated** example:

---

<details>
<summary>
:floppy_disk: <code>tfplan.json</code> (click to expand large file)
</summary>

```json
{
    "format_version": "1.1",
    "terraform_version": "1.4.6",
    "planned_values": {
        "root_module": {
            "resources": [
                {
                    "address": "aws_security_group.allow_tls",
                    "mode": "managed",
                    "type": "aws_security_group",
                    "name": "allow_tls",
                    "provider_name": "registry.terraform.io/hashicorp/aws",
                    "schema_version": 1,
                    "values": {
                        "description": "Allow TLS inbound traffic",
                        "egress": [
                            {
                                "cidr_blocks": [
                                    "0.0.0.0/0"
                                ],
                                "description": "",
                                "from_port": 0,
                                "ipv6_cidr_blocks": [],
                                "prefix_list_ids": [],
                                "protocol": "-1",
                                "security_groups": [],
                                "self": false,
                                "to_port": 0
                            }
                        ],
                        "ingress": [
                            {
                                "cidr_blocks": [
                                    "10.0.0.0/8"
                                ],
                                "description": "TLS from VPC",
                                "from_port": 443,
                                "ipv6_cidr_blocks": [],
                                "prefix_list_ids": [],
                                "protocol": "tcp",
                                "security_groups": [],
                                "self": false,
                                "to_port": 443
                            }
                        ],
                        "name": "allow_tls",
                        "revoke_rules_on_delete": false,
                        "tags": {
                            "Name": "allow_tls"
                        },
                        "tags_all": {
                            "Name": "allow_tls"
                        },
                        "timeouts": null,
                        "vpc_id": "vpc-0148ae1236544e5d0"
                    },
                    "sensitive_values": {
                        "egress": [
                            {
                                "cidr_blocks": [
                                    false
                                ],
                                "ipv6_cidr_blocks": [],
                                "prefix_list_ids": [],
                                "security_groups": []
                            }
                        ],
                        "ingress": [
                            {
                                "cidr_blocks": [
                                    false
                                ],
                                "ipv6_cidr_blocks": [],
                                "prefix_list_ids": [],
                                "security_groups": []
                            }
                        ],
                        "tags": {},
                        "tags_all": {}
                    }
                }
            ],
            "child_modules": [
                {
                    "resources": [
                        {
                            "address": "module.http_sg.aws_security_group.this_name_prefix[0]",
                            "mode": "managed",
                            "type": "aws_security_group",
                            "name": "this_name_prefix",
                            "index": 0,
                            "provider_name": "registry.terraform.io/hashicorp/aws",
                            "schema_version": 1,
                            "values": {
                                "description": "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open",
                                "name_prefix": "http-sg-",
                                "revoke_rules_on_delete": false,
                                "tags": {
                                    "Name": "http-sg"
                                },
                                "tags_all": {
                                    "Name": "http-sg"
                                },
                                "timeouts": {
                                    "create": "10m",
                                    "delete": "15m"
                                },
                                "vpc_id": "vpc-0148ae1236544e5d0"
                            },
                            "sensitive_values": {
                                "egress": [],
                                "ingress": [],
                                "tags": {},
                                "tags_all": {},
                                "timeouts": {}
                            }
                        }
                    ],
                    "address": "module.http_sg"
                }
            ]
        }
    }
}
```

</details>

---

#### :arrow_right: Create a CUE policy file

Replace any `policy.cue` file you created during Scenario 1:

:floppy_disk: `policy.cue`
```CUE
package policy

import "strings"

// the teraform plan's json form,
// placed here via the `-l tfplan:` parameter
tfplan: _

// authz: the final result of checking a plan against all policies
authz: bool
authz: ({for check, result in checks {result}} & true) != _|_

// checks: the boolean results of each individual policy
checks: [_]: bool
checks: {
	// disallow_http_security_groups asserts that the
	// http_security_groups field is an empty list
	disallow_http_security_groups: (http_security_groups & []) != _|_
}

// http_security_groups is a list of all security groups that contain the word
// "HTTP" in their description.
http_security_groups: [...string]
http_security_groups: [
	for name, config in _flatten_root_module
	if strings.Contains(config.values.description, "HTTP") {
		name
	},
]

_flatten_root_module: {
	for r in tfplan.planned_values.root_module.resources {
		(r.address): r
	}
	if tfplan.planned_values.root_module.child_modules != _|_
	for m in tfplan.planned_values.root_module.child_modules {
		_flatten_child_module & {#m: m}
	}
}
_flatten_child_module: {
	#m: {resources!: [...{...}], child_modules?: [...], ...}
	for r in #m.resources {
		(r.address): r
	}
	if #m.child_modules != _|_
	for m in #m.child_modules {
		_flatten_child_module & {#m: m}
	}
}
```

This policy examines each security group and rejects any plan where the string
"HTTP" is found in the group's description.

#### :arrow_right: Evaluate the Terraform plan against the CUE policy

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e authz
```

Expected output:

```text
false
```

Evaluate the policy whilst forcing the command to fail if the policy isn't
complied with (i.e. in a manner suitable for automated/scripted use):

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json  -e 'authz & true'
```

That command is expected to fail, with this output:

```text
conflicting values true and false:
    --expression:1:1
    --expression:1:9
    ./policy.cue:11:8
```

Display which checks caused the policy failure:

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e '{check: checks}'
```

Expected output:

```text
check: {
    disallow_http_security_groups: false
}
```

Display which security groups caused the policy failure:

:computer: `terminal`
```sh
cue eval .:policy -l tfplan: tfplan.json -e http_security_groups
```

Expected output:

```text
["module.http_sg.aws_security_group.this_name_prefix[0]"]
```

### Scenario summary

Congratulations - you've successfully checked that Terraform's proposed changes
met your policy requirement of having no "HTTP" strings in AWS security group
descriptions!

There are many different ways to write CUE to check Terraform plans, as CUE
only knows what you explicitly instruct it to test. The Terraform documentation
on each plan's
[JSON data format](https://developer.hashicorp.com/terraform/internals/) will
help you write policies for the specific situations you need to deal with.

## Next Steps

This document demonstrates some relatively unidiomatic ways of using the `cue`
CLI, in order to maintain parity with the OPA tutorial it's based on.

For some *more* idiomatic CUE, see this [parallel document](b.md).
