:- use_module(library(http/json)).

handler(json(Event), _, Response) :-
    member(fullName=FullName, Event), 
    write(FullName),
    member(FullName-Name, [
        'William'-'Bob',
        'Steven'-'Steve']),
    atom_json_term(Response, json(["nickName"=Name]), []).
    