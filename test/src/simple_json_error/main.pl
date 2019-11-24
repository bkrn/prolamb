

handler(_, _, _) :-
    throw(json([name="SomeError", message="Description of Error"])). 