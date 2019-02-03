set -o nounset
: "$STACK_PREFIX"
: "$AWS_DEFAULT_REGION"

# 1
aws cloudformation create-stack --stack-name bootstrap --template-body file://./bootstrap.yml --parameters  ParameterKey=Prefix,ParameterValue=$STACK_PREFIX

aws cloudformation wait stack-create-complete --stack-name bootstrap

# 2
aws s3 sync . s3://$STACK_PREFIX-infra/cloudformation/infra-base --exclude "*" --include "*.yml"

# 3
aws cloudformation create-stack --stack-name infra-base --capabilities CAPABILITY_NAMED_IAM \
--template-url https://s3-$AWS_DEFAULT_REGION.amazonaws.com/$STACK_PREFIX-infra/cloudformation/infra-base/infra-base-top.yml \
--parameters  ParameterKey=Prefix,ParameterValue=$STACK_PREFIX

aws cloudformation wait stack-create-complete --stack-name infra-base
