%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc Web server for web_col.

-module(web_col_web).
-author("Mochi Media <dev@mochimedia.com>").
-include("../deps/ux/src/ux_col.hrl").

-export([start/1, stop/0, loop/2]).

%% External API

start(Options) ->
    io:format("Define atoms: ~w", 
        [{non_ignorable, blanked, shifted, shift_trimmed}]),

    {DocRoot, Options1} = get_option(docroot, Options),
    Loop = fun (Req) ->
                   ?MODULE:loop(Req, DocRoot)
           end,
    mochiweb_http:start([{name, ?MODULE}, {loop, Loop} | Options1]).

stop() ->
    mochiweb_http:stop(?MODULE).

loop(Req, DocRoot) ->
    [$/] ++ Path = Req:get(path),
    try
        case Req:get(method) of
            Method when Method =:= 'GET'; Method =:= 'HEAD' ->
                case Path of
                    _ ->
                        Req:serve_file(Path, DocRoot)
                end;
            'POST' ->
                case Path of
                    "data" ->
                        PostList = Req:parse_post(),
                        InStrings = ux_string:explode($\n, ux_par:string("input", PostList)),
                        [_|_] = InStrings,
                        
                        OutStrings = ux_col:sort(InStrings, #uca_options {
                            natural_sort = ux_par:atom("natural_sort", PostList),
                            strength = ux_par:integer("strength", PostList),
                            alternate = ux_par:atom("alternate", PostList)
                        }),

                        Res = string:join(OutStrings, "\n"),

                        Req:ok({"text/html", unicode:characters_to_binary(Res)});
                    _ ->
                        Req:not_found()
                end;
            _ ->
                Req:respond({501, [], []})
        end
    catch
        Type:What ->
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
            error_logger:error_report(Report),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

%% Internal API

get_option(Option, Options) ->
    {proplists:get_value(Option, Options), proplists:delete(Option, Options)}.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

you_should_write_a_test() ->
    ?assertEqual(
       "No, but I will!",
       "Have you written any tests?"),
    ok.

-endif.
