:- set_prolog_flag(verbose, silent).

:- use_module(library(pairs)).
:- use_module(library(http/json)).
:- use_module(library(http/http_json)).
:- use_module(library(apply), [maplist/3]).
:- use_module(library(http/http_client), [http_get/3, http_post/4]).

entrance(Mod, Pred) :-
    getenv("_HANDLER", E),
    split_string(E, ".", "", L),
    maplist(string_to_atom, L, [Mod, Pred]).

invocation_url(U) :- 
    getenv("AWS_LAMBDA_RUNTIME_API", V),
    format(atom(U), "http://~w/2018-06-01/runtime", V).

next(Request, Headers, Id) :-
    invocation_url(U),
    format(atom(URL), "~w/invocation/next", U),
    http_get(URL, Request, [connection('Keep-alive'), 
                            headers(Headers), 
                            header('lambda_runtime_aws_request_id', Id)]).

respond(Id, Payload) :-
    invocation_url(U),
    format(atom(URL), "~w/invocation/~w/response", [U, Id]),
    http_post(URL, atom('application/json', Payload), _, []).

handle_error(Id, HandlerError) :-
    write(HandlerError),
    HandlerError = json([errorType=_, errorMessage=_]) ->
    post_handler_error(Id, HandlerError) ;
    (format(atom(Message), "~w", HandlerError),
    post_handler_error(Id, json([errorType='HandlerException', 
                                 errorMessage=Message]))).

post_handler_error(Id, Json) :-
    invocation_url(U),
    format(atom(URL), "~w/invocation/~w/error", [U, Id]),
    atom_json_term(Body, Json, []),
    http_post(URL, atom('application/json', Body), _, []).

post_init_error(Json) :-
    invocation_url(U),
    format(atom(URL), "~w/init/error", U),
    atom_json_term(Body, Json, []),
    http_post(URL, atom('application/json', Body), _, []).

main_loop(Pred) :-
    next(Event, Headers, Id),
    context(Headers, Context),
    catch(
        ((call(Pred, Event, Context, FnOutput), ground(FnOutput)) ->
            respond(Id, FnOutput) 
            ; handle_error(Id, json([errorType="HandlerFailure", 
                errorMessage="Handler predicate failed to resolve"]))), 
        ThrownError, 
        (handle_error(Id, ThrownError))
    ),
    main_loop(Pred).

load_handler(Mod) :-
    catch(ensure_loaded(Mod), _, exists_file('STATIC_MODULE')).

load_handler(Mod) :-
    writeln('Could not find module'),
    format(string(Message), "Could not find module named '~w'", Mod),
    post_init_error(json([errorType="InvalidHandlerModule", 
                                errorMessage=Message])), fail.

valid_handler(Pred) :-
    current_functor(Pred, 3).

valid_handler(Pred) :-
    writeln('Could not find handler'),
    format(string(Message), "Could not find callable named '~w'", Pred),
    post_init_error(json([errorType="InvalidHandlerCallable", 
                            errorMessage=Message])), fail.
                        
prolamb_go :-
    entrance(Mod, Pred),
    (load_handler(Mod), valid_handler(Pred)) -> (
            main_loop(Pred)
    ); true.

env_context(['_HANDLER',
    'AWS_REGION',
    'AWS_EXECUTION_ENV',
    'AWS_LAMBDA_FUNCTION_NAME',
    'AWS_LAMBDA_FUNCTION_MEMORY_SIZE',
    'AWS_LAMBDA_FUNCTION_VERSION',
    'AWS_LAMBDA_LOG_GROUP_NAME',
    'AWS_LAMBDA_LOG_STREAM_NAME',
    'AWS_ACCESS_KEY_ID',
    'AWS_SECRET_ACCESS_KEY',
    'AWS_SESSION_TOKEN',
    'LANG',
    'TZ',
    'LAMBDA_TASK_ROOT',
    'LAMBDA_RUNTIME_DIR',
    'PATH',
    'LD_LIBRARY_PATH',
    'AWS_LAMBDA_RUNTIME_API']).

getenv_or_default(A, B) :-
    getenv(A, B) -> true ; B = ''.

context(Headers, Context) :-
    env_context(VarNames),
    maplist(getenv_or_default, VarNames, VarValues),
    pairs_keys_values(EnvContext, VarNames, VarValues),
    Context = context(headers(Headers), env(EnvContext)).
