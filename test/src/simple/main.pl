:- use_module(library(http/json)).

handler(_, _, Response) :-
    atom_json_term(Response, json(["fullName"="William"]), []).
    