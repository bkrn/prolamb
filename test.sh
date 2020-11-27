#! /usr/bin/env bash
set -e

##──── build archives for test lambdas ───────────────────────────────────────────────────
echo "Build Prolamb Docker Image"
docker build --tag prolamb/prolamb:latest -f build.Dockerfile .
cd test/src

dirlist=$(find . -mindepth 1 -maxdepth 1 -type d)
for dir in $dirlist
do
    echo "Build ${dir} test lambda .zip"
    cd $dir && rm -f bundle.zip || true
    docker run --rm -v $PWD:/dist prolamb/prolamb:latest &> /dev/null
    cd ..
done
cd ..

echo "Terraform Init"
cd terraform
terraform init
if [ "${CI}" = "true" ]; then
    terraform import aws_lambda_function.simple_lambda ProlambSimple
    terraform import aws_lambda_function.json_error_lambda ProlambJsonError
    terraform import aws_lambda_function.simple_json_error_lambda ProlambSimpleJsonError
    terraform import aws_lambda_function.error_lambda ProlambError
    terraform import aws_lambda_function.bad_module_lambda ProlambBadModule
    terraform import aws_lambda_function.bad_callable_lambda ProlambBadCallable
    terraform import aws_lambda_function.context_lambda ProlambContext
    terraform import aws_lambda_function.event_lambda ProlambEvent
    terraform import aws_lambda_function.fail_lambda ProlambFail
    terraform import aws_lambda_function.false_lambda ProlambFalse
    terraform import aws_lambda_function.unbound_lambda ProlambUnbound
fi
terraform apply -auto-approve
cd ..

echo "Running tests"

invoke_function() {
    jq -Ssc '.[0]' <(aws lambda invoke --function-name $1 --payload "$2" /dev/stdout)
}

# Expect Success
SIMPLE=$(invoke_function ProlambSimple '{}')
CONTEXT=$(invoke_function ProlambContext '{}' | grep -o 'LANG-en_US.UTF-8')
EVENT=$(invoke_function ProlambEvent '{ "fullName": "William" }')

# Expect Failure
ERROR=$(invoke_function ProlambError '{}')
FAIL=$(invoke_function ProlambFail '{}')
UNBOUND=$(invoke_function ProlambUnbound '{}')
FALSE=$(invoke_function ProlambFalse '{}')
JSON_ERROR=$(invoke_function ProlambJsonError '{}')
SIMPLE_JSON_ERROR=$(invoke_function ProlambSimpleJsonError '{}')
BAD_MODULE=$(invoke_function ProlambBadModule '{}')
BAD_CALLABLE=$(invoke_function ProlambBadCallable '{}')

echo "Adding assert"

[ -f assert.sh ] || wget https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh -O assert.sh &>/dev/null

md5sum --status -c checksums

. assert.sh

# Test success
assert "echo '${SIMPLE}'" '{"fullName":"William"}'
assert "echo '${CONTEXT}'" 'LANG-en_US.UTF-8'
assert "echo '${EVENT}'" '{"nickName":"Bob"}'

#  Test failure
assert "echo '${FAIL}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${FALSE}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${UNBOUND}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${ERROR}'" '{"errorMessage":"This space intentionally left blank","errorType":"HandlerException"}'
assert "echo '${JSON_ERROR}'" '{"errorMessage":"I am JSON","errorType":"JsonError"}'
assert "echo '${SIMPLE_JSON_ERROR}'" '{"errorMessage":"json([name=SomeError,message=Description of Error])","errorType":"HandlerException"}'
assert "echo '${BAD_MODULE}'" '{"errorMessage":"Could not find module named grain","errorType":"InvalidHandlerModule"}'
assert "echo '${BAD_CALLABLE}'" '{"errorMessage":"Could not find callable named hand","errorType":"InvalidHandlerCallable"}'

assert_end "simple invocation"
