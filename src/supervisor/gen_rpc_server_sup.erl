%%% -*-mode:erlang;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
%%% ex: set ft=erlang fenc=utf-8 sts=4 ts=4 sw=4 et:
%%%
%%% Copyright 2015 Panagiotis Papadomitsos. All Rights Reserved.
%%%

-module(gen_rpc_server_sup).
-author("Panagiotis Papadomitsos <pj@ezgr.net>").

%%% Behaviour
-behaviour(supervisor).

%%% Supervisor functions
-export([start_link/0, start_child/1, stop_child/1]).

%%% Supervisor callbacks
-export([init/1]).

%%% ===================================================
%%% Supervisor functions
%%% ===================================================
-spec start_link() -> supervisor:startlink_ret().
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% Launch a local receiver and return the port
-spec start_child({inet:ip4_address(), inet:port_number()}) -> {ok, any()} | {error, any()}.
start_child(Peer) when is_tuple(Peer) ->
    ok = lager:debug("event=starting_new_server peer=\"~s\"", [gen_rpc_helper:peer_to_string(Peer)]),
    case supervisor:start_child(?MODULE, [Peer]) of
        {error, {already_started, CPid}} ->
            %% If we've already started the child, terminate it and start anew
            ok = stop_child(CPid),
            supervisor:start_child(?MODULE, [Peer]);
        {error, OtherError} ->
            {error, OtherError};
        {ok, TPid} ->
            {ok, TPid}
    end.

%% Terminate and unregister a child server
-spec stop_child(Pid::pid()) -> ok.
stop_child(Pid) when is_pid(Pid) ->
    ok = lager:debug("event=stopping_server server_pid=\"~p\"", [Pid]),
    %% Terminate the acceptor child first and then
    _ = supervisor:terminate_child(?MODULE, Pid),
    _ = supervisor:delete_child(?MODULE, Pid),
    ok.

%%% ===================================================
%%% Supervisor callbacks
%%% ===================================================
init([]) ->
    {ok, {{simple_one_for_one, 100, 1}, [
        {gen_rpc_server, {gen_rpc_server,start_link,[]}, temporary, 5000, worker, [gen_rpc_server]}
    ]}}.
