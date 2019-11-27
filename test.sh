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
cd extern/localstack
echo "Build modified localstack image"
docker build -f localstack.Dockerfile --tag prolamb/localstack:latest . &> /dev/null
cd ../../..
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

strip_status() {
    local OPEN=0
    local CLOSE=0
    local S=""
    for (( i=0; i<${#1}; i++ )); do
        C=${1:$i:1}
        if [[ "${C}" == "{" ]]; then 
            ((++OPEN))
        elif [[ "${C}" == "}" ]]; then 
            ((++CLOSE)) 
        fi
        if (( OPEN > 0 )); then 
            if (( OPEN >= CLOSE )) && [[ "${C}" != "\n" ]]; then 
                local S="${S}${C}"
            fi
            if (( OPEN == CLOSE )); then 
                i=${#1}
            fi
        fi
    done
    echo "${S}"
}

invoke_function() {
    local RESULT=$(awslocal lambda invoke --function-name $1 --payload "$2" /dev/stdout)
    strip_status "${RESULT}"
}

# Success
SIMPLE=$(invoke_function ProlambSimple '{}')
CONTEXT=$(invoke_function ProlambContext '{}' | grep -o 'LANG-en_US.UTF-8')
EVENT=$(invoke_function ProlambEvent '{ "fullName": "William" }')

# Failure
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
. assert.sh

# Test success
assert "echo '${SIMPLE}'" '{"fullName":"William"}'
assert "echo '${CONTEXT}'" 'LANG-en_US.UTF-8'
assert "echo '${EVENT}'" '{"nickName":"Bob"}'

# Test failure
assert "echo '${FAIL}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${FALSE}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${UNBOUND}'" '{"errorMessage":"Handler predicate failed to resolve","errorType":"HandlerFailure"}'
assert "echo '${ERROR}'" '{"errorMessage":"This space intentionally left blank","errorType":"HandlerException"}'
assert "echo '${JSON_ERROR}'" '{"errorMessage":"I am JSON","errorType":"JsonError"}'
assert "echo '${SIMPLE_JSON_ERROR}'" '{"errorMessage":"json([name=SomeError,message=Description of Error])","errorType":"HandlerException"}'
assert "echo '${BAD_MODULE}'" '{"errorMessage":"Could not find module named grain","errorType":"InvalidHandlerModule"}'
assert "echo '${BAD_CALLABLE}'" '{"errorMessage":"Could not find callable named hand","errorType":"InvalidHandlerCallable"}'

assert_end "simple invocation"
