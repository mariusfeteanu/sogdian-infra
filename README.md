## Prerequisites

You need a privileged account to bootstrap the project. If you don't have one, you need to work out for yourself the permissions needed for bootstrapping.
Only one copy of this project can be deployed in one account.
Multiple copies can be used if you use different accounts, and a different prefix param set in each.

You need to set the following env variables for the commands below to work. If using docker for development, you need to set them before you start the container.
  - export AWS_PROFILE=admin-dev
  - export AWS_DEFAULT_REGION=eu-west-1
  - export STACK_PREFIX=sogdian-dev

or, for Windows Powershell:

  - $env:AWS_PROFILE="admin-dev"
  - $env:AWS_DEFAULT_REGION="eu-west-1"
  - $env:STACK_PREFIX="sogdian-dev"

The variables above are specific to your deployment.

All these commands below are tested on Linux. If you have another OS, you can try to make that work yourself or you can use the docker dev environment included with the project.
  - `docker-compose build`
  - `docker-compose.exe run devenv`

## Bootstrapping
1. Deploy the boostrap stack
```bash
# create the stack
aws cloudformation create-stack --stack-name bootstrap --template-body file://./bootstrap.yml --parameters  ParameterKey=Prefix,ParameterValue=$STACK_PREFIX
# wait for completion
aws cloudformation wait stack-create-complete --stack-name bootstrap
```
2. The step above would have created an s3 bucket for you. Upload the yml files from this project to it.
```bash
aws s3 sync . s3://$STACK_PREFIX-infra/cloudformation/infra-base --exclude "*" --include "*.yml"
```
3. Deploy the cloudformation stack.
```bash
# create the stack
aws cloudformation create-stack --stack-name infra-base --capabilities CAPABILITY_NAMED_IAM \
--template-url https://s3-$AWS_DEFAULT_REGION.amazonaws.com/$STACK_PREFIX-infra/cloudformation/infra-base/infra-base-top.yml \
--parameters  ParameterKey=Prefix,ParameterValue=$STACK_PREFIX
# wait for completion
aws cloudformation wait stack-create-complete --stack-name infra-base
```
  * N.B.: The stack name above must be named `infra-base`.
  * N.B.: CAPABILITY_NAMED_IAM is required above.

## CICD Integration

You should now have an infrastructure stack up and running. This includes some simple CI/CD, so now we need to set-up our repositories to use it.

1. You must have an IAM user with CodeCommit privileges. See:
  - https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html
  - Creation of IAM users for humans is outside the scope of this document.
  - The only policy you need to attach to this user is AWSCodeCommitPowerUser. If this is a shared AWS account, you need to write up your own minimal policy document.
  - The user does not actually need web console access.
  - You need to retrieve the `HTTPS Git credentials for AWS CodeCommit`.

2. Connect the local repository to code commit, replacing your region and prefix in the url below:
```bash
# Remove current mappings (e.g. github)
git remote rm origin
# Add new origin
git remote add origin https://git-codecommit.$AWS_DEFAULT_REGION.amazonaws.com/v1/repos/$STACK_PREFIX-infra
git remote -v
# Push to your own codecommit repo. Insert here password from step 1.
git push --set-upstream origin master
```

3. This base infra stack contains the code pipeline definitions for the web analytics stack, but the code to create it. You need to deploy it using it's own repository.


## Cleanup

We need to remove the stacks in the reverse order they were created. This includes any stacks created by code pipeline, which in this version just deploys it does not clean up.

We also need to manually remove any files stored in s3, before deleting the respective stacks.

Just to clarify, this will delete all data you created through the pipeline and all the artifacts we deployed.

1. web analytics:
```bash
aws s3 rm --recursive s3://$STACK_PREFIX-delivery-web-event
aws s3 rm --recursive s3://$STACK_PREFIX-convert-web-event
aws cloudformation delete-stack --stack-name web-analytics
```

2. infra root
```bash
aws cloudformation delete-stack --stack-name infra-base
```
3. boostrap
```bash
aws s3 rm --recursive s3://$STACK_PREFIX-infra
aws cloudformation delete-stack --stack-name bootstrap
```
