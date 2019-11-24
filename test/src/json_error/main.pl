

handler(_, _, _) :-
    throw(json([errorType="JsonError", errorMessage="I am JSON"])). 