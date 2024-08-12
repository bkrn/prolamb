terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_lambda_function" "simple_lambda" {
  filename      = "../src/simple/bundle.zip"
  function_name = "ProlambSimple"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/simple/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "json_error_lambda" {
  filename      = "../src/json_error/bundle.zip"
  function_name = "ProlambJsonError"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/json_error/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "simple_json_error_lambda" {
  filename      = "../src/simple_json_error/bundle.zip"
  function_name = "ProlambSimpleJsonError"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/simple_json_error/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "error_lambda" {
  filename      = "../src/error/bundle.zip"
  function_name = "ProlambError"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/error/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "bad_module_lambda" {
  filename      = "../src/simple/bundle.zip"
  function_name = "ProlambBadModule"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "grain.handler"
  source_code_hash = filebase64sha256("../src/simple/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "bad_callable_lambda" {
  filename      = "../src/simple/bundle.zip"
  function_name = "ProlambBadCallable"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.hand"
  source_code_hash = filebase64sha256("../src/simple/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "context_lambda" {
  filename      = "../src/context/bundle.zip"
  function_name = "ProlambContext"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/context/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "event_lambda" {
  filename      = "../src/event/bundle.zip"
  function_name = "ProlambEvent"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/event/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "fail_lambda" {
  filename      = "../src/fail/bundle.zip"
  function_name = "ProlambFail"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/fail/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "false_lambda" {
  filename      = "../src/false/bundle.zip"
  function_name = "ProlambFalse"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/false/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "unbound_lambda" {
  filename      = "../src/unbound/bundle.zip"
  function_name = "ProlambUnbound"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/unbound/bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "simple_lambda_static" {
  filename      = "../src/simple/static_bundle.zip"
  function_name = "ProlambSimpleStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/simple/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "json_error_lambda_static" {
  filename      = "../src/json_error/static_bundle.zip"
  function_name = "ProlambJsonErrorStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/json_error/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "simple_json_error_lambda_static" {
  filename      = "../src/simple_json_error/static_bundle.zip"
  function_name = "ProlambSimpleJsonErrorStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/simple_json_error/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "error_lambda_static" {
  filename      = "../src/error/static_bundle.zip"
  function_name = "ProlambErrorStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/error/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "bad_module_lambda_static" {
  filename      = "../src/simple/static_bundle.zip"
  function_name = "ProlambBadModuleStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "grain.handler"
  source_code_hash = filebase64sha256("../src/simple/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "bad_callable_lambda_static" {
  filename      = "../src/simple/static_bundle.zip"
  function_name = "ProlambBadCallableStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.hand"
  source_code_hash = filebase64sha256("../src/simple/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "context_lambda_static" {
  filename      = "../src/context/static_bundle.zip"
  function_name = "ProlambContextStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/context/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "event_lambda_static" {
  filename      = "../src/event/static_bundle.zip"
  function_name = "ProlambEventStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/event/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "fail_lambda_static" {
  filename      = "../src/fail/static_bundle.zip"
  function_name = "ProlambFailStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/fail/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "false_lambda_static" {
  filename      = "../src/false/static_bundle.zip"
  function_name = "ProlambFalseStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/false/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}

resource "aws_lambda_function" "unbound_lambda_static" {
  filename      = "../src/unbound/static_bundle.zip"
  function_name = "ProlambUnboundStatic"
  role          = "arn:aws:iam::869128890907:role/iam_for_lambda"
  handler       = "main.handler"
  source_code_hash = filebase64sha256("../src/unbound/static_bundle.zip")
  runtime = "provided"
  timeout = 15
}
