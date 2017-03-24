#!/bin/bash
STACK_NAME="choice-as"

run_title() {
  echo "======== "$1" ========"
}

budget_syntax_check() {
  # extract and parse the code to see if there are syntax errors
  grep 'choiceAsUpdateHandleLambda:' -A -1 infrastructure.cf.yml | \
    grep choiceAsLambdaExecutionRole -B -1 | \
    egrep '^            |^$' | \
    sed 's/^            //' | \
    python
}

run_deploy() {
  run_title "Running Deploy"

  deployed_id=$(aws cloudformation list-stacks | \
    jq '.StackSummaries[] | select(.StackName == "'$STACK_NAME'" and .StackStatus != "DELETE_COMPLETE") | .StackId' | \
    sed 's/"//g')

  echo "deployed_id: '$deployed_id'"
  echo

  if [[ "$deployed_id" == "" ]]; then
    echo 'Creating stack'
    aws cloudformation create-stack --stack-name $STACK_NAME \
      --template-body file://infrastructure.cf.yml \
      --capabilities CAPABILITY_IAM
  else
    echo 'Updating stack'
    aws cloudformation update-stack --stack-name $STACK_NAME \
      --template-body file://infrastructure.cf.yml \
      --capabilities CAPABILITY_IAM
  fi

  echo
  echo "To view the stack status, run:"
  echo "$0 deploy_status"
  echo
}

run_deploy_status() {
    stack_name="q-and-a-db"
    status_cmd="aws cloudformation describe-stacks --stack-name $STACK_NAME | jq '.Stacks[] | {StackId, Outputs, StackStatus}'"
    eval $status_cmd
}

if [[ "$1" == "deploy" ]]; then
  budget_syntax_check && run_deploy && run_deploy_status
elif [[ "$1" == "deploy_status" ]]; then
  run_deploy_status
else
  echo "Usage: "$0" deploy|deploy_status"
fi
