:- use_module(library(http/json)).

handler(_, Context, Response) :-
    format(string(Message), "~w", Context),
    atom_json_term(Response, json(["context"=Message]), []).