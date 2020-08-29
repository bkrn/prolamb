:- use_module(library(dcg/basics)).
:- use_module(library(readutil)).
:- use_module(library(charsio)).

extractor([]) --> [].
extractor([Test|Tests]) --> anything, "% DOCTEST", string(Test), "% DOCTEST", anything, extractor(Tests).
anything --> [].
anything --> [_], anything.
whitespace --> [].
whitespace --> " ", whitespace.
whitespace --> "\n", whitespace.

:- dynamic(doctests/0).

run_doc_tests(File) :- 
    read_file_to_codes(File, Codes, []),
    phrase(extractor([T|_]), Codes, []),
    new_memory_file(Handle),
    insert_memory_file(Handle, 0, T),
    open_memory_file(Handle, read, S),
    load_files(readme, [stream(S)]),
    free_memory_file(Handle),
    doctests().