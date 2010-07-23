%%% See http://github.com/mojombo/bert.erl for documentation.
%%% MIT License - Copyright (c) 2009 Tom Preston-Werner <tom@mojombo.com>

-module(bert).
-version('1.1.0').
-author("Tom Preston-Werner").

-export([encode/1, decode/1]).

%%---------------------------------------------------------------------------
%% Public API

-spec encode(term()) -> binary().

encode(Term) ->
  term_to_binary(encode_term(Term)).

-spec decode(binary()) -> term().

decode(Bin) ->
  decode_term(binary_to_term(Bin)).

%%---------------------------------------------------------------------------
%% Encode

-spec encode_term(term()) -> term().

encode_term(Term) ->
  case Term of
    [] -> {bert, nil};
    true -> {bert, true};
    false -> {bert, false};
    Dict when is_record(Term, dict, 9) ->
      {bert, dict, [encode_term(V) || V <- dict:to_list(Dict)]};
    List when is_list(Term) ->
      [encode_term(V) || V <- List];
    Tuple when is_tuple(Term) ->
      TList = tuple_to_list(Tuple),
      TList2 = [encode_term(V) || V <- TList],
      list_to_tuple(TList2);
    _Else -> Term
  end.

%%---------------------------------------------------------------------------
%% Decode

-spec decode_term(term()) -> term().

decode_term(Term) ->
  case Term of
    {bert, nil} -> [];
    {bert, true} -> true;
    {bert, false} -> false;
    {bert, dict, Dict} ->
      dict:from_list([decode_term(V) || V <- Dict]);
    {bert, Other} ->
      {bert, Other};
    List when is_list(Term) ->
      [decode_term(V) || V <- List];
    Tuple when is_tuple(Term) ->
      TList = tuple_to_list(Tuple),
      TList2 = [decode_term(V) || V <- TList],
      list_to_tuple(TList2);
    _Else -> Term
  end.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

%% encode

encode_list_nesting_test() ->
  Bert = term_to_binary([foo, {bert, true}]),
  Bert = encode([foo, true]).

encode_tuple_nesting_test() ->
  Bert = term_to_binary({foo, {bert, true}}),
  Bert = encode({foo, true}).

%% decode

decode_list_nesting_test() ->
  Bert = term_to_binary([foo, {bert, true}]),
  Term = [foo, true],
  Term = decode(Bert).

decode_tuple_nesting_test() ->
  Bert = term_to_binary({foo, {bert, true}}),
  Term = {foo, true},
  Term = decode(Bert).

%% Using encode_term/decode_term to make reading failed test cases easier
roundtrip_dict_test() ->
  Bert = {bert, dict, [{key, value}]},
  Term = dict:from_list([{key, value}]),
  ?assertEqual(Bert, encode_term(Term)),
  ?assertEqual(Term, decode_term(Bert)).

roundtrip_dict_nesting_test() ->
  Bert = {bert, dict, [{key, {bert, dict, [{key, value}]}}]},
  InnerTerm = dict:from_list([{key, value}]),
  OuterTerm = dict:from_list([{key, InnerTerm}]),
  ?assertEqual(Bert, encode_term(OuterTerm)),
  ?assertEqual(OuterTerm, decode_term(Bert)).

-endif.
