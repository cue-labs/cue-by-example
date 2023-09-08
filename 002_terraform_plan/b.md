# Validating Terraform plan output with idiomatic CUE
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>

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

:arrow_right: Create a CUE policy file

:floppy_disk: `policy.cue`
```cue
package policy

// the teraform plan's json form,
// placed here via the `-l tfplan:` parameter
tfplan: _

tfplan: policy.reject_aws_iam_changes
tfplan: policy.reject_aws_autoscaling_group_deletions

// no aws_iam changes
policy: reject_aws_iam_changes: {
	let Type = "aws_iam"
	let AcceptAction = "no-op"

	resource_changes?: [ ...AcceptableChange]
	let AcceptableChange = Type_match | Type_mismatch

	let Type_mismatch = {type!: !=Type}
	let Type_match = {
		type!: Type
		change?: actions!: [...AcceptAction]
	}
}

// no aws_autoscaling_group deletions
policy: reject_aws_autoscaling_group_deletions: {
	let Type = "aws_autoscaling_group"
	let RejectAction = "delete"

	resource_changes?: [ ...AcceptableChange]
	let AcceptableChange = Type_match | Type_mismatch

	let Type_mismatch = {type!: !=Type}
	let Type_match = {
		type!: Type
		change?: actions!: [...!=RejectAction]
	}
}
```

This policy file checks that no changes to AWS IAM resources are being
proposed, and that no AWS Auto Scaling groups are being deleted - even if that
deletion is part of a delete-and-recreate operation.

#### :arrow_right: Evaluate the Terraform plan against the CUE policy

:computer: `terminal`
```sh
cue vet -c .:policy -l tfplan: tfplan.json
```

As with all use of `cue vet`, no news is good news!

Because the plan was acceptable to the 2 policies contained in the policy file,
`cue vet` printed nothing, and its exit code was zero.

:arrow_right: Simular a policy failure

Replace your `policy.cue` file with this slightly different version, which has
the `policy.reject_aws_autoscaling_group_deletions.RejectAction` alias changed
so that it rejects "create" actions - actions which we know are present in our
Terraform plan's output.

:floppy_disk: `policy.cue`
```cue
package policy

// the teraform plan's json form,
// placed here via the `-l tfplan:` parameter
tfplan: _

tfplan: policy.reject_aws_iam_changes
tfplan: policy.reject_aws_autoscaling_group_creations

// no aws_iam changes
policy: reject_aws_iam_changes: {
	let Type = "aws_iam"
	let AcceptAction = "no-op"

	resource_changes?: [ ...AcceptableChange]
	let AcceptableChange = Type_match | Type_mismatch

	let Type_mismatch = {type!: !=Type}
	let Type_match = {
		type!: Type
		change?: actions!: [...AcceptAction]
	}
}

// no aws_autoscaling_group creations
policy: reject_aws_autoscaling_group_creations: {
	let Type = "aws_autoscaling_group"
	// this RejectAction is /probably/ not what you want, as it has been
	// changed to prompt a policy /failure/.
	let RejectAction = "create"

	resource_changes?: [ ...AcceptableChange]
	let AcceptableChange = Type_match | Type_mismatch

	let Type_mismatch = {type!: !=Type}
	let Type_match = {
		type!: Type
		change?: actions!: [...!=RejectAction]
	}
}
```

Repeat the `cue vet` command from before:

:computer: `terminal`
```sh
cue vet -c .:policy -l tfplan: tfplan.json
```

This time, the command is expected to *fail* and to show the following output:

```text
tfplan.resource_changes.0: 3 errors in empty disjunction:
tfplan.resource_changes.0.type: conflicting values "aws_iam" and "aws_autoscaling_group":
    ./policy.cue:7:9
    ./policy.cue:12:13
    ./policy.cue:15:23
    ./policy.cue:15:26
    ./policy.cue:16:25
    ./policy.cue:20:10
    ./tfplan.json:100:15
tfplan.resource_changes.0.type: invalid value "aws_autoscaling_group" (out of bound !="aws_autoscaling_group"):
    ./policy.cue:35:30
    ./policy.cue:18:30
    ./tfplan.json:100:15
tfplan.resource_changes.0.change.actions.0: invalid value "create" (out of bound !="create"):
    ./policy.cue:38:26
    ./tfplan.json:105:11
```

Like many CLI programs, `cue vet`'s primary way of communicating that some
input data wasn't acceptable is to return an exit code greater than zero.

Understanding the *error messages* that `cue vet` displays can seem daunting at
first, but there's an easy way to figure out where the problem lies. Ignore the
lines mentioning the `policy.cue` file, and focus on the 3 lines that the error
message highlights in `tfplan.json`.

In our example, `cue` told us that lines 100 and 105 are to blame. Your exact
line numbers might differ, as your version of Terraform might be different.

Check the relevant section of your `tfplan.json` file. Given the line numbers
in our example error message, here's the surrounding section of the file, from
lines 96 to 106:

:computer: `terminal`
```console
user@host$ cat -n tfplan.json | awk 'NR >= 96 && NR <= 106'
    96	  "resource_changes": [
    97	    {
    98	      "address": "aws_autoscaling_group.my_asg",
    99	      "mode": "managed",
   100	      "type": "aws_autoscaling_group",
   101	      "name": "my_asg",
   102	      "provider_name": "aws",
   103	      "change": {
   104	        "actions": [
   105	          "create"
   106	        ],
```

The `cue` error message shows us that *either* line 100 or line 105 is at
fault. In other words, `"type": "aws_autoscaling_group"` can't co-exist with a
`"create"` action - just as we hoped when we modified `policy.cue`.

### Scenario summary

Congratulations - you've successfully checked that Terraform's proposed changes
met your policy requirements of making no IAM changes and not deleting any Auto
Scaling groups!

There are many different ways to write CUE to check Terraform plans, as CUE
only knows what you explicitly instruct it to test. The Terraform documentation
on each plan's
[JSON data format](https://developer.hashicorp.com/terraform/internals/) will
help you write policies for the specific situations you need to deal with.

## Scenario 2: A plan that uses a Terraform module

### Steps

TODO

### Scenario summary

TODO
