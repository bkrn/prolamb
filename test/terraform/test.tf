provider "aws" {
  version                     = "~> 2.34"
  access_key                  = "mock_access_key"
  region                      = "us-east-1"
  s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://127.0.0.1:4567"
    cloudformation = "http://127.0.0.1:4581"
    cloudwatch     = "http://127.0.0.1:4582"
    dynamodb       = "http://127.0.0.1:4569"
    es             = "http://127.0.0.1:4578"
    firehose       = "http://127.0.0.1:4573"
    iam            = "http://127.0.0.1:4593"
    kinesis        = "http://127.0.0.1:4568"
    lambda         = "http://127.0.0.1:4574"
    route53        = "http://127.0.0.1:4580"
    redshift       = "http://127.0.0.1:4577"
    s3             = "http://127.0.0.1:4572"
    secretsmanager = "http://127.0.0.1:4584"
    ses            = "http://127.0.0.1:4579"
    sns            = "http://127.0.0.1:4575"
    sqs            = "http://127.0.0.1:4576"
    ssm            = "http://127.0.0.1:4583"
    stepfunctions  = "http://127.0.0.1:4585"
    sts            = "http://127.0.0.1:4592"
  }
}


resource "aws_lambda_function" "simple_lambda" {
  filename      = "../src/simple/bundle.zip"
  function_name = "ProlambSimple"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/simple/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "json_error_lambda" {
  filename      = "../src/json_error/bundle.zip"
  function_name = "ProlambJsonError"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/json_error/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "simple_json_error_lambda" {
  filename      = "../src/simple_json_error/bundle.zip"
  function_name = "ProlambSimpleJsonError"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/simple_json_error/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "error_lambda" {
  filename      = "../src/error/bundle.zip"
  function_name = "ProlambError"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/error/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "bad_module_lambda" {
  filename      = "../src/simple/bundle.zip"
  function_name = "ProlambBadModule"
  role          = "dontmatter"
  handler       = "grain.handler"
  source_code_hash = "${filebase64sha256("../src/simple/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "bad_callable_lambda" {
  filename      = "../src/simple/bundle.zip"
  function_name = "ProlambBadCallable"
  role          = "dontmatter"
  handler       = "main.hand"
  source_code_hash = "${filebase64sha256("../src/simple/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "context_lambda" {
  filename      = "../src/context/bundle.zip"
  function_name = "ProlambContext"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/context/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "event_lambda" {
  filename      = "../src/event/bundle.zip"
  function_name = "ProlambEvent"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/event/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "fail_lambda" {
  filename      = "../src/fail/bundle.zip"
  function_name = "ProlambFail"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/fail/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "false_lambda" {
  filename      = "../src/false/bundle.zip"
  function_name = "ProlambFalse"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/false/bundle.zip")}"
  runtime = "provided"
}

resource "aws_lambda_function" "unbound_lambda" {
  filename      = "../src/unbound/bundle.zip"
  function_name = "ProlambUnbound"
  role          = "dontmatter"
  handler       = "main.handler"
  source_code_hash = "${filebase64sha256("../src/unbound/bundle.zip")}"
  runtime = "provided"
}
