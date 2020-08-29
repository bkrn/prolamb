[![Build Status](https://travis-ci.com/bkrn/prolamb.svg?branch=master)](https://travis-ci.com/bkrn/prolamb)

# Prolamb

SWI-Prolog bootstrap for the AWS Lambda provided runtime

## What?

You can build a .zip file using the docker image in this repo and your own handler scripts that is ready to be uploaded into an AWS lambda function using the `provided` runtime.

## Quick Start

Write a handler/3:

```prolog
%! handler(++Event:list, ++Context:list, --Response:text).
% Clearly this will complain about singleton variables
% but there is value to naming the variables here
handler(json(Event), Context, Response) :- 
  Response = '{"hello": "world"}'.
```

Place it into some file like `main.pl`

then build your bundle like:

```sh
docker pull prolamb/prolamb:latest
# location of main.pl
cd $SOURCE_DIRECTORY 
# Map your current directory (location of your SWI-prolog source code)
# into the /dist directory of the build container using volumes
docker run --rm -v $PWD:/dist prolamb/prolamb:latest
# After the build is complete you'll have a brand new bundle.zip
# archive that can be used in a lambda instance with the "provided" 
# runtime
```

If you're using other source files they must be in or children of $SOURCE_DIRECTORY. Otherwise they won't make it into bundle.zip.

Be sure that the handler option of your lambda is set to `file.predicate`. So if your entry file is main.pl and the predicate handler is handler/3 then the handler option should be `main.handler`.

## Guide

### Writing a Handler

Your handler should have an arity of three. The first two arguments, the event and context, are grounded and contain the invocation inputs. The last, the function's response, is bound to the the text type you want your function to respond with by your handler predicate.

For example a service that matches nicknames and fullnames might have a handler like:

```prolog
% DOCTEST
% this example is tested in place as a part of the build pipeline

:- use_module(library(http/json)).
:- use_module(library(date)).

lambda_local_datetime(context(headers(H), _), DT) :-
  member('TZ'(TimeZone), H),
  member(TimeZone-TZ, ['PST'-(5 * 60 * 60)]),
  I is TZ,
  get_time(TS),
  stamp_date_time(TS, DT, I).

names(FullName, NickName, _) :-
  member(FullName-NickName, [
        'Nicholas'-'Nick',
        'William'-'Bob',
        'William'-'Robert',
        'Steven'-'Steve']).

% During the holiday season recognize additional nick names
names('Nicholas', 'Santa', Context) :-
  lambda_local_datetime(Context, DT),
  date_time_value(month, DT, 12),
  date_time_value(day, DT, Day),
  Day < 26.

% Given an event described by the JSON schema:
% {"type": "object", "properties": {"nickName": {"type": "string"}, "fullName": {"type": "string"}}}
% The response is described by the JSON schema:
% {"type": "object", "required": ["possibleNames], "properties": {"possibleNames: {"type": "array", "items": 
%   {"type": "object", "properties": {"fullName": {"type": "string"}, "nickName": {"type": "string"}}}}}}
handler(json(Event), Context, Response) :-
    (member(fullName=FullName, Event); true),
    (member(nickName=NickName, Event); true),
    findall(json([fullname=FullName, nickName=NickName]), 
            names(FullName, NickName, Context), 
            Names),
    atom_json_term(Response, json([possibleNames=Names]), []).

% this is the goal that is run as part of the build pipeline.
doctests() :-
  % Match on fullName
  handler(json([fullName='Nicholas']), context(headers(['TZ'('PST')]), _), Response1),
  ground(Response1),
  Response1 = '{"possibleNames": [ {"fullname":"Nicholas", "nickName":"Nick"} ]}',
  % Match on nickName
  handler(json([nickName='Bob']), context(headers(['TZ'('PST')]), _), Response2),
  ground(Response2),
  Response2 = '{"possibleNames": [ {"fullname":"William", "nickName":"Bob"} ]}',
  % There is no ground!
  handler(json([]), context(headers(['TZ'('PST')]), _), Response3),
  ground(Response3),
  Response3 = '{\n  "possibleNames": [\n    {"fullname":"Nicholas", "nickName":"Nick"},\n    {"fullname":"William", "nickName":"Bob"},\n    {"fullname":"William", "nickName":"Robert"},\n    {"fullname":"Steven", "nickName":"Steve"}\n  ]\n}'.

% DOCTEST
```

#### Event Argument

The JSON event trigger processed using http/json so that the format is as specified here https://www.swi-prolog.org/pldoc/man?section=jsonsupport - the actual schema of the JSON depends on the lambda integration. but it will always be `json(_)`

#### Context Argument

Request headers and variables specified in the lambda environment. Shape is `context(headers([Name(Value), ...]), env([Key-Value, ...]))`

#### Response Argument

Should be attached to an atom or string that is JSON formatted in the proper AWS response type schema. For example if you're using an API Gateway proxy integration `Repsonse` should be attached to an atom/string of the shape found here: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format

#### Exceptions

Feel free to throw exceptions. If it is of the form `json([errorType=Type,errorMessage=Message])` then the run time will use your literal as the error otherwise it will attempt to format your throw and use `json([errorType='HandlerException',errorMessage=Message])` where `format(string(Message), "~w", ThingThatWasThrown)`.
