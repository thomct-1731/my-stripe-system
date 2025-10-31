# with Terraform

![AWS](../../../images/aws-terraform.png)

## Install

Refer how to install [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) base on your OS.

## How to use

### Initialization

#### I. Create environments & services

- Create environment folders and services folders in environment. Examples:
  - [ ] DEV
  - [ ] STG
  - [ ] PROD

- Symlink variables.tf file of environment to each service folder of it and add this symlink file to gitignore with two method

  *1. Symlink specific service*

  - Excute `make symlink e=<environment-name> s=<service-name>`. Example:

    ```bash
    make symlink e=dev s=general
    ```

  *2. Symlink all services*

  - Excute `make symlink_all e=<environment-name>`. Example:

    ```bash
    make symlink_all e=dev
    ```

  *3. Unsymlink specific service*

  - Excute `make unsymlink e=<environment-name> s=<service-name>`. Example:

    ```bash
    make unsymlink e=dev s=general
    ```

  *4. Unsymlink all services*

  - Excute `make unsymlink_all e=<environment-name>`. Example:

    ```bash
    make unsymlink_all e=dev
    ```

#### [II. Terraform init](https://www.terraform.io/cli/commands/init)

*1. Init specific service*

- Excute `make init e=<environment-name> s=<service-name>`. Example:

    ```bash
    make init e=dev s=general
    ```

*2. Init upgrade for service*

- Excute `make init_upgrade e=<environment-name> s=<service-name>`. Example:

    ```bash
    make init_upgrade e=dev s=general
    ```

*3. Init migrate state for service*

- Excute `make init_migrate e=<environment-name> s=<service-name>`. Example:

    ```bash
    make init_migrate e=dev s=general
    ```

*4. Init all services*

- Excute `make init_all e=<environment-name>`. Example:

    ```bash
    make init_all e=dev
    ```

### Deployment

#### [I. Terraform plan](https://www.terraform.io/cli/commands/plan)

*1. Plan specific service*

- Excute `make plan e=<environment-name> s=<service-name>` (If you want to plan before destroy, excute `make plan_destroy e=<environment-name> s=<service-name>` instead). Example:

    ```bash
    make plan e=dev s=general
    ```

*2. Plan specific service with module target*

- Excute `make plan_target e=<environment-name> s=<service-name> t='<module-name>'` (If you want to plan before destroy target, excute `make plan_destroy_target e=<environment-name> s=<service-name> t='<module-name>'` instead). Example:

    ```bash
    make plan_target e=dev s=general t=module.vpc
    ```

*3. Plan all services*

- Excute `make plan_all e=<environment-name>`(If you want to plan before destroy all, excute `make plan_destroy_all e=<environment-name>` instead). Example:

    ```bash
    make plan_all e=dev
    ```

#### [II. Terraform apply](https://www.terraform.io/cli/commands/apply)

*1. Apply specific service*

- Excute `make apply e=<environment-name> s=<service-name>`. Example:

    ```bash
    make apply e=dev s=general
    ```

*2. Apply specific service with module target*

- Excute `make apply_target e=<environment-name> s=<service-name> t='<module-name>'`. Example:

    ```bash
    make apply_target e=dev s=general t=module.vpc
    ```

*3. Apply all services*

- Excute `make apply_all e=<environment-name>`. Example:

    ```bash
    make apply_all e=dev
    ```

#### [III. Terraform destroy](https://www.terraform.io/cli/commands/apply)

*1. Destroy specific service*

- Excute `make destroy e=<environment-name> s=<service-name>`. Example:

    ```bash
    make destroy e=dev s=general
    ```

*2. Destroy specific service with module target*

- Excute `make destroy_target e=<environment-name> s=<service-name> t='<module-name>'`. Example:

    ```bash
    make destroy_target e=dev s=general t=module.vpc
    ```

*3. Destroy all services*

- Excute `make destroy_all e=<environment-name>`. Example:

    ```bash
    make destroy_all e=dev
    ```

#### IV. Other Terraform commands

*1. Recreate a resource in service*

- Excute `make taint e=<environment-name> s=<service-name> t='<module-name>'`. Example:

    ```bash
    make taint e=dev s=general t='module.rds_aurora.aws_rds_cluster.aurora_cluster'
    ```

*2. **Do not** recreate a resource in service*

- Excute `make untaint e=<environment-name> s=<service-name> t='<module-name>'`. Example:

    ```bash
    make untaint e=dev s=general t='module.rds_aurora.aws_rds_cluster.aurora_cluster'
    ```

*3. List all state of service*

- Excute `make state_list e=<environment-name> s=<service-name>`. Example:

    ```bash
    make state_list e=dev s=general
    ```

*4. Show state of resource in service*

- Excute `make state_show e=<environment-name> s=<service-name> t='<module-name>'`. Example:

    ```bash
    make state_show e=dev s=general t='module.rds_aurora.aws_rds_cluster.aurora_cluster'
    ```

*5. Import state of resource into service*

- Excute `make state_import e=<environment-name> s=<service-name> t='<module-name>' ot='<other-module-name>'`. Example:

    ```bash
    make state_import e=dev s=general t='module.rds_aurora.aws_cloudwatch_log_group.aurora_log_group["error"]' ot=/aws/rds/cluster/sgaas-gami-dev-rds-aurora-cluster/error
    ```

*6. Remove state of resource out of service*

- Excute `make state_rm e=<environment-name> s=<service-name> t='<module-name>'`. Example:

    ```bash
    make state_rm e=dev s=general t='module.rds_aurora.aws_rds_cluster.aurora_cluster'
    ```

*7. Move state of resource to another state in service*

- Excute `make state_mv e=<environment-name> s=<service-name> t='<module-name>' ot='<other-module-name>'`. Example:

    ```bash
    make state_mv e=dev s=general t='module.rds_aurora.aws_cloudwatch_log_group.aurora_log_group["error"]' ot='module.rds_aurora.aws_cloudwatch_log_group.aurora_log_group["new-error"]'
    ```

## Structure

### Example

```
├── terraform
│   ├── envs
│   │   ├── dev
│   │   └── stg
│   │   └── prod
│   └── README.md
└── terraform-dependencies
    ├── codebuild
    │   └── buildspec.yml
    ├── codedeploy
    │   ├── appspec.yml
    │   └── hooks
    │       ├── 1.pull-and-config.sh
    │       ├── 2.build-and-deploy.sh
    │       ├── 3.start.sh
    │       └── 4.validate.sh
    └── lambda-function
```

### Vars

- Create variables for main
  - [x] variables.tf
- Values of variables for each environment
  - [ ] terraform.dev.tfvars
  - [ ] terraform.stg.tfvars
  - [ ] terraform.prod.tfvars

### Main

- Using **Modules** method
  - containers for multiple resources that are used together
  - the main way to package and reuse resource configurations with Terraform.
- [**Module Blocks**](https://www.terraform.io/language/modules/syntax#module-blocks)
- [**Module Sources from Github**](https://www.terraform.io/language/modules/sources#github) are tagged and released here <https://github.com/framgia/sun-infra-iac/tags>

Example:

```terraform
  module "example" {
    source = "git@github.com:framgia/sun-infra-iac.git//modules/iam-role?ref=terraform-aws-iam_v0.1.2"
  }
```

### Backend

- Backends primarily determine where Terraform stores its state. Terraform uses this persisted state data to keep track of the resources it manages. Since it needs the state in order to know which real-world infrastructure objects correspond to the resources in a configuration, everyone working with a given collection of infrastructure resources must be able to access the same state data.

### Outputs

- Output values make information about your infrastructure available on the command line, and can expose information for other Terraform configurations to use. Output values are similar to return values in programming languages.

## Naming & Coding Conventions

1. Name of the service and `Name` tag you will create following format

   ```
   Name = "${var.project}--${var.env}-${var.name}-<aws/azure/gcp-service-name>"
   ```

Besides `${var.name}`, you can use `${var.type}`, `${var.region}`...depends on how many resources in a module or the way you create it.

2. `Resource and data source arguments`

- The name of a resource should be more descriptive. Examples:

  ```terraform
  resource "aws_subnet" "subnet_private" {}
  resource "aws_route_table" "route_private" {}
  ```

- If not, the name of a resource can be the same as the resource name that the provider defined. Examples:

  ```terraform
  resource "aws_ssm_parameter" "ssm_parameter" {}
  ```

- Notes:
  - Always use singular nouns for names.
  - Use _ (underscore) instead of - (dash) everywhere (in resource names, data source names, variable names, outputs, etc).
  - Prefer to use lowercase letters and numbers (even though UTF-8 is supported)

3. Usage of `count`/`for_each`

- Include argument `count`/`for_each` inside resource or data source block as the first argument at the top and separate by newline after it. Example:

  ```terraform
  resource "aws_route_table" "route_public" {
    count = 2

    vpc_id = "vpc-12345678"
    # ... remaining arguments omitted
  }

  resource "aws_route_table" "route_private" {
    for_each = toset(["one", "two"])

    vpc_id = "vpc-12345678"
    # ... remaining arguments omitted
  }
  ```

- When using conditions in an argument `count`/`for_each` prefer boolean values instead of using `length` or other expressions.

4. Placement of `tags`

- Include argument `tags`, if supported by resource, as the last real argument, following by depends_on and lifecycle, if necessary. All of these should be separated by a single empty line.

   ```terraform
   resource "aws_nat_gateway" "nat_gw" {
     count = 2

     allocation_id = "..."
     subnet_id     = "..."

     tags = {
       Name = "${var.project}--${var.env}-..."
     }

     depends_on = [aws_internet_gateway.internet_gw]

     lifecycle {
       create_before_destroy = true
     }
   }   
   ```

- Do not add `Project` & `Environment` tags in resources because we add it by default tag at `provider` function in `backend.tf` file.

5. Variables

- Use the plural form in a variable name when type is list(...) or map(...).
- Order keys in a variable block like this: description , default, type, validation.
- Always include description on all variables even if you think it is obvious (**Prefer write it from [Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)**).

6. Outputs

- Good structure for the name of output looks like {name}_{attribute} , where:
  - {name} is a name of resource or data source.
  - {attribute} is an attribute returned by the output.
- If the returned value is a list it should have a plural name. See example.
- Always include description for all outputs even if you think it is obvious.
- Example: `resource "aws_rds_cluster_instance" "rds_cluster" {}` ->

```terraform
output "rds_cluster_endpoints" {
  description = "A list of all cluster instance endpoints"
  value       = aws_rds_cluster_instance.rds_cluster.*.endpoint
}
```

7. `Modules`

- Resources:
  - In the module, if you have 2 or more resources:
    - The name of the variable will have a prefix of the name of the resource.
    - Each resource will create a variable and each attribute of the resource will use its child variables (There will be some exceptions).
    - If you meet a block attribute, create one variable and use also its child variables for the attributes inside it.
    - Example:

      ```terraform
      resource "aws_lambda_function" "lambda_function" {
        function_name                  = "${var.project}-${var.env}-${var.lambda_function.name}-lambda"
        description                    = "from ${var.service}: to Lambda"
        role                           = var.lambda_function.role
        timeout                        = var.lambda_function.timeout
        memory_size                    = var.lambda_function.memory_size

        ...

        # Lambda in VPC
        dynamic "vpc_config" {
          for_each = var.lambda_function.vpc_config != {} ? [var.lambda_function.vpc_config] : []
          content {
            subnet_ids         = var.lambda_function.vpc_config.subnet_ids
            security_group_ids = var.lambda_function.vpc_config.security_group_ids
          }
        }

        dynamic "dead_letter_config" {
          for_each = var.lambda_function.dead_letter_config
          content {
            target_arn = var.lambda_function.dead_letter_config.target_arn
          }
        }
      }

      # For API Gateway
      resource "aws_lambda_permission" "lambda_permission_api_gateway" {
        for_each = { for value in var.lambda_function_api_gateway : value.name => value }

        statement_id  = "AllowExecutionFromAPIGateway-${each.value.name}"
        action        = "lambda:InvokeFunction"
        function_name = aws_lambda_function.lambda_function.function_name
        principal     = "apigateway.amazonaws.com"
        source_arn    = "${each.value.arn}/*/*/*"
      }
      ```

  - In the module, if you have one resource:
    - The name of the variable will be the same as the attribute of the resource
    - Each attribute will create a variable. (There will be some exceptions).
    - If you meet a block attribute, create one variable and use also its child variables for the attributes inside it.
    - Example:

      ```terraform
      resource "aws_ssm_parameter" "ssm_parameter" {
        name   = var.name
        value  = var.value
        key_id = var.key_id
        type   = var.type

        tags = {
          Name = var.name
        }
      }
      ```

- Variables:
  - In the module, if you use `project`, `env`, `region` variables... Put it first in #basic block, for another variables of resources give them another block and separate by newline after
  - Example:

    ```terraform
    #modules/lambda/_variables.tf
    #basic
    variable "project" {
      description = "Name of project"
      type        = string
    }
    variable "env" {
      description = "Name of project environment"
      type        = string
    }
    variable "service" {
      description = "AWS service name is associated with Lambda"
      type        = string
    }
    variable "region" {
      description = "Region of environment"
      type        = string
    }

    #lambda zip
    variable "lambda_zip_python" {
      description = "Use to automatically install packages for Python and compress them into zip file for Lambda Function"
      default     = {}
      type        = any
    }

    #lambda
    variable "lambda_function" {
      description = "All configurations of a Lambda Function resource"
      type = object(...)
      }

    variable "lambda_function_api_gateway" {
      description = "Provide the Name and ARN of the API Gateway you want to trigger to the Lambda Function"
      default     = []
      type = list(object(...)
      )
    }
    ```

- Outputs:
  - Separated by blocks by function or resource created
  - Example:

    ```terraform
    #modules/vpc/_outputs.tf
    #VPC
    output "vpc_id" {
      value       = aws_vpc.vpc.id
      description = "ID of VPC"
    }

    #Subnet
    output "subnet_private_id" {
      value       = var.private_cidrs != null ? aws_subnet.subnet_private.*.id : []
      description = "ID of Private Subnet"

    }
    output "subnet_public_id" {
      value       = aws_subnet.subnet_public.*.id
      description = "ID of Public Subnet"
    }

    #Gateway
    output "nat_gateway_public_ip" {
      value       = var.private_cidrs != null ? aws_nat_gateway.nat_gateway.*.public_ip : []
      description = "Public IP of NAT Gateway"
    }
    output "internet_gateway_id" {
      value       = aws_internet_gateway.internet_gateway.id
      description = "ID of Internet Gateway"
    }
    ```

## Create new modules

- Check out to base branch `terraform-<cloud-platform>-base` (Example: `terraform-aws-base`). Remember fetch latest & pull to your local branch.
- Create new branch like `terraform-aws-<terraform-module>` (Example: `terraform-aws-vpc`) from `terraform-aws-base` branch. Example:

  ```
  git checkout terraform-aws-base
  git checkout -b terraform-aws-vpc
  git push origin terraform-aws-vpc
  ```

- **Note:** Describe your module in README.md at root folder.
