set -o nounset
: "$STACK_PREFIX"

# 1
aws s3 rm --recursive s3://$STACK_PREFIX-delivery-web-event
aws s3 rm --recursive s3://$STACK_PREFIX-convert-web-event
aws cloudformation delete-stack --stack-name web-analytics

aws cloudformation wait stack-delete-complete --stack-name web-analytics

# 2
aws cloudformation delete-stack --stack-name infra-base

aws cloudformation wait stack-delete-complete --stack-name infra-base

# 3
aws s3 rm --recursive s3://$STACK_PREFIX-infra
aws cloudformation delete-stack --stack-name bootstrap

aws cloudformation wait stack-delete-complete --stack-name bootstrap
