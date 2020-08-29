#! /usr/bin/env bash

set -e

swipl -s doctest.pl -g "run_doc_tests('README.md')." -t 'halt.'