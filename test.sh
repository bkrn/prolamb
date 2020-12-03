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

dirlist=$(find . -mindepth 1 -maxdepth 1 -type d)
for dir in $dirlist
do
    echo "Build ${dir} static test lambda .zip"
    cd $dir && rm -f static_bundle.zip || true
    docker run --rm -e "STATIC_MODULE=main" -e "BUNDLE_NAME=static_bundle.zip" -v $PWD:/dist prolamb/prolamb:latest &> /dev/null
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
    terraform import aws_lambda_function.simple_lambda ProlambSimpleStatic
    terraform import aws_lambda_function.json_error_lambda ProlambJsonErrorStatic
    terraform import aws_lambda_function.simple_json_error_lambda ProlambSimpleJsonErrorStatic
    terraform import aws_lambda_function.error_lambda ProlambErrorStatic
    terraform import aws_lambda_function.bad_module_lambda ProlambBadModuleStatic
    terraform import aws_lambda_function.bad_callable_lambda ProlambBadCallableStatic
    terraform import aws_lambda_function.context_lambda ProlambContextStatic
    terraform import aws_lambda_function.event_lambda ProlambEventStatic
    terraform import aws_lambda_function.fail_lambda ProlambFailStatic
    terraform import aws_lambda_function.false_lambda ProlambFalseStatic
    terraform import aws_lambda_function.unbound_lambda ProlambUnboundStatic
fi
terraform apply -auto-approve
cd ..

echo "Running tests"

invoke_function() {
    jq -Ssc '.[0]' <(aws lambda invoke --cli-binary-format raw-in-base64-out --function-name $1 --payload "$2" /dev/stdout)
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

# Expect Success
STATIC_SIMPLE=$(invoke_function ProlambSimpleStatic '{}')
STATIC_CONTEXT=$(invoke_function ProlambContextStatic '{}' | grep -o 'LANG-en_US.UTF-8')
STATIC_EVENT=$(invoke_function ProlambEventStatic '{ "fullName": "William" }')

# Expect Failure
STATIC_ERROR=$(invoke_function ProlambErrorStatic '{}')
STATIC_FAIL=$(invoke_function ProlambFailStatic '{}')
STATIC_UNBOUND=$(invoke_function ProlambUnboundStatic '{}')
STATIC_FALSE=$(invoke_function ProlambFalseStatic '{}')
STATIC_JSON_ERROR=$(invoke_function ProlambJsonErrorStatic '{}')
STATIC_SIMPLE_JSON_ERROR=$(invoke_function ProlambSimpleJsonErrorStatic '{}')
STATIC_BAD_MODULE=$(invoke_function ProlambBadModuleStatic '{}')
STATIC_BAD_CALLABLE=$(invoke_function ProlambBadCallableStatic '{}')

echo "Adding assert"

[ -f assert.sh ] || wget https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh -O assert.sh &>/dev/null

md5sum --status -c checksums

. assert.sh

# Test success
assert "echo '${SIMPLE}'" '{"fullName":"William"}'
assert "echo '${CONTEXT}'" 'LANG-en_US.UTF-8'
assert "echo '${EVENT}'" '{"nickName":"Bob"}'
assert "echo '${STATIC_SIMPLE}'" '{"fullName":"William"}'
assert "echo '${STATIC_CONTEXT}'" 'LANG-en_US.UTF-8'
assert "echo '${STATIC_EVENT}'" '{"nickName":"Bob"}'
assert "echo '${STATIC_BAD_MODULE}'" '{"fullName":"William"}'

#  Test failure
assert "echo '${FAIL}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${FALSE}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${UNBOUND}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${ERROR}'" '{"errorMessage":"This space intentionally left blank","errorType":"HandlerException"}'
assert "echo '${JSON_ERROR}'" '{"errorMessage":"I am JSON","errorType":"JsonError"}'
assert "echo '${SIMPLE_JSON_ERROR}'" '{"errorMessage":"json([name=SomeError,message=Description of Error])","errorType":"HandlerException"}'
assert "echo '${BAD_MODULE}'" '{"errorMessage":"Could not find module named grain","errorType":"InvalidHandlerModule"}'
assert "echo '${BAD_CALLABLE}'" '{"errorMessage":"Could not find callable named hand","errorType":"InvalidHandlerCallable"}'
assert "echo '${STATIC_FAIL}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${STATIC_FALSE}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${STATIC_UNBOUND}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${STATIC_ERROR}'" '{"errorMessage":"This space intentionally left blank","errorType":"HandlerException"}'
assert "echo '${STATIC_JSON_ERROR}'" '{"errorMessage":"I am JSON","errorType":"JsonError"}'
assert "echo '${STATIC_SIMPLE_JSON_ERROR}'" '{"errorMessage":"json([name=SomeError,message=Description of Error])","errorType":"HandlerException"}'
assert "echo '${STATIC_BAD_CALLABLE}'" '{"errorMessage":"Could not find callable named hand","errorType":"InvalidHandlerCallable"}'

assert_end "simple invocation"
