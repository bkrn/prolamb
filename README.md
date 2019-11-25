# Prolamb

SWI-Prolog bootstrap for the AWS Lambda provided runtime

## About

Build a .zip file targetting AWS's lambda provided runtime by bringing your own handler and wrapping it in this runtime. 

## Quick Start

Write a handler/3:

```prolog
%!      handler(++Event:list, ++Context:list, --Response:text).
handler(_, _, Response) :- 
  Response = '{"hello": "world"}'.
```

Place it into some file like `main.pl`

then build your bundle like:

```sh
docker pull bkrn/prolamb:latest
cd $SOURCE_DIRECTORY # location of main.pl
# Map your current directory (location of your SWI-prolog source code)
# into the /dist directory of the build container using volumes
docker run --rm -v $PWD:/dist bkrn/prolamb:latest
# After the build is complete you'll have a brand new bundle.zip
# archive that can be used in a lambda instance with the "provided" 
# runtime
```

If you're using other source files they must be in or bew children of $SOURCE_DIRECTORY. Otherwise they won't make it into bundle.zip.

Be sure that the handler option of your lambda is set to `file.predicate`. So if your entry file is main.pl and the predicate handler is handler/3 then the handler option should be `main.handler`.

## Guide

### Event Argument

The JSON event trigger processed using http/json so that the format is as specified here https://www.swi-prolog.org/pldoc/man?section=jsonsupport - the actual schema of the JSON depends on the almbda integration. 

### Context Argument

Request headers and environment variables specified in the lambda environment. Shape is `context(headers([Name(Value), ...]), env([Key-Value, ...]))`

### Response Argument

Should be attached to an atom or string that is JSON formatted in the proper AWS response type schema. For example if you're using an API Gateway proxy integration `Repsonse` should be attached to an atom/string of the shape found here: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
