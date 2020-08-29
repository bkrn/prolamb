#! /usr/bin/env bash

set -e

SOURCE=$(awk 'f{ if (/DOCTEST/){printf "%s", buf; f=0; buf=""} else buf = buf $0 ORS}; /DOCTEST/{f=1}' README.md)

T1=$(
echo "${SOURCE}" | swipl -g "load_files(stdin, [stream(user_input)])" -g "handler(json([fullName='Nicholas']), context(headers(['TZ'('PST')]), _), Response), write(Response)." -t halt | \
    jq '.possibleNames' | \
    jq 'length'
)

T2=$(
echo "${SOURCE}" | swipl -g "load_files(stdin, [stream(user_input)])" -g "handler(json([]), context(headers(['TZ'('PST')]), _), Response), write(Response)." -t halt | \
    jq '.possibleNames' | \
    jq 'length'
)


[ -f assert.sh ] || wget https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh -O assert.sh &>/dev/null
. assert.sh

assert "echo '${T1}'" 1
assert "echo '${T2}'" 4

assert_end "doc_test"