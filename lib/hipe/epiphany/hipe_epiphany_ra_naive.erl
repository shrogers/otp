%% -*- erlang-indent-level: 2 -*-
%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2005-2009. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%

-module(hipe_epiphany_ra_naive).
-export([ra/2]).

-include("hipe_epiphany.hrl").

ra(Defun, _Options) ->	% -> {Defun, Coloring}
  {NewDefun,_DidSpill} =
    hipe_epiphany_ra_postconditions:check_and_rewrite2(Defun, [], 'naive'),
  {NewDefun, []}.
