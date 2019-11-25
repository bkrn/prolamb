#! /usr/bin/env bash
set -e

docker rm -f prolamb-localstack &> /dev/null || true
##──── build archives for test lambdas ───────────────────────────────────────────────────
echo "Build Prolamb Docker Image"
docker build --tag prolamb:latest -f build.Dockerfile .
cd test/src

dirlist=$(find $1 -mindepth 1 -maxdepth 1 -type d)
for dir in $dirlist
do
    echo "Build ${dir} test lambda .zip"
    cd $dir && rm -f bundle.zip || true
    docker run --rm -v $PWD:/dist prolamb:latest &> /dev/null
    cd ..
done
cd ..

##──── Build our slightly special verion of local stack ──────────────────────────────────
# Localstack has a built in suffix check depending on the lambda run time
# For provided it searches for .sh by default but we have a .pl so we edit that in
# the source and pass it in
cd localstack
echo "Build modified localstack image"
docker build -f localstack.Dockerfile --tag prolamb/localstack:latest . &> /dev/null
cd ../..
docker run -p 4574:4574 -v /var/run/docker.sock:/var/run/docker.sock \
    --privileged --name prolamb-localstack \
    prolamb/localstack >test/localstack.log &
echo "Wait for local stack to come up"
(tail -f -n0 test/localstack.log &) | grep -q 'Ready.'

echo "Terraform Init"
cd test/terraform
terraform init
terraform apply -auto-approve
cd ..

echo "Running tests"
SIMPLE=$(echo $(awslocal lambda invoke --function-name ProlambSimple --payload '{}' /dev/stdout 2> /dev/stdout) | grep -Po '{.*?}' | head -1)
echo $SIMPLE
ERROR=$(echo $(awslocal lambda invoke --function-name ProlambError --payload '{}' /dev/stdout 2> /dev/stdout) | grep -Po '{.*?}' | head -1)
echo $ERROR
FAIL=$(echo $(awslocal lambda invoke --function-name ProlambFail --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $FAIL
UNBOUND=$(echo $(awslocal lambda invoke --function-name ProlambUnbound --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $UNBOUND
FALSE=$(echo $(awslocal lambda invoke --function-name ProlambFalse --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $FALSE
JSON_ERROR=$(echo $(awslocal lambda invoke --function-name ProlambJsonError --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $JSON_ERROR
SIMPLE_JSON_ERROR=$(echo $(awslocal lambda invoke --function-name ProlambSimpleJsonError --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $SIMPLE_JSON_ERROR
BAD_MODULE=$(echo $(awslocal lambda invoke --function-name ProlambBadModule --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $BAD_MODULE
BAD_CALLABLE=$(echo $(awslocal lambda invoke --function-name ProlambBadCallable --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $BAD_CALLABLE
CONTEXT=$(echo $(awslocal lambda invoke --function-name ProlambContext --payload '{}' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1 | grep -Po 'LANG-en_US.UTF-8')
echo $CONTEXT
EVENT=$(echo $(awslocal lambda invoke --function-name ProlambEvent --payload '{ "fullName": "William" }' /dev/stdout 2>/dev/stdout) | grep -Po '{.*?}' | head -1)
echo $EVENT

echo "Adding assert"
. assert.sh

assert "echo ${SIMPLE}" '{fullName:William}'
assert "echo ${FAIL}" '{ errorType: HandlerFailure, errorMessage: Handler predicate failed to resolve }'
assert "echo ${FALSE}" '{ errorType: HandlerFailure, errorMessage: Handler predicate failed to resolve }'
assert "echo ${UNBOUND}" '{ errorType: HandlerException, errorMessage: error(format_argument_type(a,_8838),context(system:format/3,_8844)) }'
assert "echo ${CONTEXT}" 'LANG-en_US.UTF-8'
assert "echo ${EVENT}" '{nickName:Bob}'
assert "echo ${ERROR}" "{ errorType: HandlerException, errorMessage: This space intentionally left blank }"
assert "echo ${JSON_ERROR}" "{ errorType: JsonError, errorMessage: I am JSON }"
assert "echo ${SIMPLE_JSON_ERROR}" "{ errorType: HandlerException, errorMessage: json([name=SomeError,message=Description of Error]) }"
assert "echo ${BAD_MODULE}" "{ errorType: InvalidHandlerModule, errorMessage: Could not find module named 'grain' }"
assert "echo ${BAD_CALLABLE}" "{ errorType: InvalidHandlerCallable, errorMessage: Could not find callable named 'hand' }"

assert_end "simple invocation"
