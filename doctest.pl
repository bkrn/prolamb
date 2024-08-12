:- use_module(library(dcg/basics)).
:- use_module(library(readutil)).
:- use_module(library(charsio)).

extractor([]) --> [].
extractor([Test|Tests]) --> anything, "```", whites, "prolog", string(Test), "```", anything, extractor(Tests).
anything --> [].
anything --> [_], anything.

:- dynamic(doctest/0).

run(File) :-
    read_file_to_codes(File, Codes, []),
    phrase(extractor(Tests), Codes, []),
    run_doc_tests(Tests, 0). 

run_doc_tests([], Ix) :- 
    aggregate_all(count, nth_clause(doctest, _, _), Count),
    (Count = 0, P = ""; P = "s"),
    format('Running ~D doc test~w found in ~D snippets.\n', [Count, P, Ix]),
    aggregate_all(count, doctest, Count).

run_doc_tests([T|Ts], Ix) :- 
    new_memory_file(Handle),
    insert_memory_file(Handle, 0, T),
    open_memory_file(Handle, read, S),
    load_files(readme, [stream(S)]), !,
    free_memory_file(Handle),
    run_doc_tests(Ts, Ix + 1).
