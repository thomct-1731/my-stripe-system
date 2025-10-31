#!/bin/bash
#set -x
profile_gen_token=$1
profile=$2
account_id=$3
iam_user_name=$4
token_code=$5
aws_sts_credentials="$(aws sts get-session-token --profile $profile_gen_token --serial-number arn:aws:iam::$account_id:mfa/$iam_user_name --query "Credentials" --output "json" --token-code $token_code)"

if [ "$?" != "0" ] ;then
    echo "Please re-input"
else
    {
    echo "Begin replace"
    aws_access_key_id="$(echo "$aws_sts_credentials" | jq -r '.AccessKeyId')"
    echo "aws access key: $aws_access_key_id"
    aws_secret_access_key="$(echo "$aws_sts_credentials" | jq -r '.SecretAccessKey')"
    aws_secret_access_key="$(echo $aws_secret_access_key | sed -e "s|/|\\\/|g" )"
    # echo "aws secret access key: $aws_secret_access_key"
    aws_session_token="$(echo "$aws_sts_credentials" | jq -r '.SessionToken')"
    aws_session_token="$(echo $aws_session_token | sed -e "s|/|\\\/|g" )"
    # echo "aws session_token: $aws_session_token"
    sed -i '/'$profile'/{N;s/aws_access_key_id.*/aws_access_key_id = '$aws_access_key_id'/}' $HOME/.aws/credentials
    sed -i '/'$profile'/{N;N;s/aws_secret_access_key.*/aws_secret_access_key = '$aws_secret_access_key'/}' $HOME/.aws/credentials
    sed -i '/'$profile'/{N;N;N;s/aws_session_token.*/aws_session_token = '$aws_session_token'/}' $HOME/.aws/credentials
    echo "End replace"
    }
fi
