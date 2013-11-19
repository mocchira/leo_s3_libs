%%======================================================================
%%
%% Leo S3-Libs
%%
%% Copyright (c) 2012-2013 Rakuten, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% ---------------------------------------------------------------------
%% Leo S3-Libs - Bucket TEST
%% @doc
%% @end
%%======================================================================
-module(leo_s3_bucket_tests).

-author('Yosuke Hara').

-include("leo_s3_bucket.hrl").
-include("leo_s3_libs.hrl").
-include_lib("eunit/include/eunit.hrl").


%%--------------------------------------------------------------------
%% TEST
%%--------------------------------------------------------------------
-ifdef(EUNIT).

-define(ACCESS_KEY_0, <<"leofs">>).
-define(ACCESS_KEY_1, <<"fuglen">>).
-define(ACCESS_KEY_2, <<"elk">>).

-define(Bucket0,  <<"bucket0">>).
-define(Bucket1,  <<"bucket1">>).
-define(Bucket2,  <<"bucket2">>).
-define(Bucket3,  <<"bucket3">>).
-define(Bucket4,  <<"bucket4">>).
-define(Bucket5,  <<"bucket5">>).
-define(Bucket6,  <<"bucket6">>).
-define(Bucket7,  <<"bucket7">>).
-define(Bucket8,  <<"bucket8">>).
-define(Bucket9,  <<"b01012013">>). %% https://github.com/leo-project/leofs/issues/75
-define(Bucket10, <<"bucket10">>).

-define(BucketTooShort, <<"sh">>).
-define(BucketInvalidStart,  <<".myawsbucket">>).
-define(BucketInvalidStart2, <<"-myawsbucket">>).
-define(BucketInvalidStart3, <<"_myawsbucket">>).
-define(BucketInvalidEnd,    <<"myawsbucket.">>).
-define(BucketInvalidEnd2,   <<"myawsbucket-">>).
-define(BucketInvalidEnd3,   <<"myawsbucket_">>).
-define(BucketInvalidLabel,  <<"my..examplebucket">>).
-define(BucketInvalidIPAddr, <<"192.168.1.1">>).
-define(BucketInvalidChar1,  <<"hogeHoge">>).
-define(BucketValid1,        <<"my.aws.bucket">>).
-define(BucketValid2,        <<"wsbucket.1">>).
-define(BucketValid3,        <<"ws-bucket.1">>).
-define(BucketValid4,        <<"ws_bucket.1">>).

bucket_test_() ->
    {foreach, fun setup/0, fun teardown/1,
     [{with, [T]} || T <- [fun mnesia_suite_/1,
                           fun ets_suite_/1
                          ]]}.

setup() ->
    application:start(crypto),
    ok.

teardown(_) ->
    application:stop(crypto),
    meck:unload(),
    ok.

mnesia_suite_(_) ->
    meck:new(leo_s3_auth),
    meck:expect(leo_s3_auth, has_credential, fun(_) -> true end),
    meck:expect(leo_s3_auth, get_owner_by_access_key,
                fun(_) ->
                        {ok, <<"leofs">>}
                end),

    meck:new(leo_s3_user),
    meck:expect(leo_s3_user, find_by_access_key_id,
                fun(_) -> {ok, <<"leofs">>} end),

    ok = leo_s3_bucket:start(master, [], 3),
    ok = leo_s3_bucket:create_bucket_table('ram_copies', [node()]),

    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket0),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket1),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket2),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket3),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket4),
    ok = leo_s3_bucket:put(?ACCESS_KEY_1, ?Bucket5),
    ok = leo_s3_bucket:put(?ACCESS_KEY_1, ?Bucket6),

    {ok, Ret0} = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_0),
    ?assertEqual(5, length(Ret0)),

    {ok, Ret1} = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_1),
    ?assertEqual(2, length(Ret1)),

    {ok, Ret2} = leo_s3_bucket:find_all(),
    ?assertEqual(7, length(Ret2)),

    ok = leo_s3_bucket:delete(?ACCESS_KEY_1, ?Bucket5),
    ok = leo_s3_bucket:delete(?ACCESS_KEY_1, ?Bucket6),
    not_found = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_1),

    5 = leo_s3_bucket_data_handler:size({mnesia, leo_s3_buckets}),
    {ok, Ret3}  = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_0, 0),
    ?assertEqual(5, length(Ret3)),

    ok = leo_s3_bucket:head(?ACCESS_KEY_0, ?Bucket1),

    {error, forbidden} = leo_s3_bucket:head(?ACCESS_KEY_1, ?Bucket1),
    not_found = leo_s3_bucket:head(?ACCESS_KEY_1, ?Bucket5),

    %% bucket name validations
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketTooShort),
    BucketTooLong = lists:seq(1, 256),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, BucketTooLong),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidStart),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidStart2),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidStart3),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidEnd),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidEnd2),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidEnd3),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidLabel),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidIPAddr),
    {error, badarg} = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketInvalidChar1),

    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketValid1),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketValid2),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketValid3),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?BucketValid4),

    {error, 'already_has'} = leo_s3_bucket:put(?ACCESS_KEY_1, ?BucketValid1),
    {error, 'already_has'} = leo_s3_bucket:put(?ACCESS_KEY_1, ?BucketValid2),

    %% Retrieve buckets including owner
    {ok, Buckets0} = leo_s3_bucket:find_all_including_owner(),
    {ok, Buckets1} = leo_s3_bucket:find_all(),
    ?assertEqual(true, length(Buckets0) == length(Buckets1)),

    %% https://github.com/leo-project/leofs/issues/75
    ok = leo_s3_bucket:put(?ACCESS_KEY_1, ?Bucket9),

    %% ACL related
    %% default to be private
    {ok, [#bucket_acl_info{user_id = ?ACCESS_KEY_0,
                           permissions = [full_control]}]} = leo_s3_bucket:get_acls(?Bucket0),
    leo_s3_bucket:update_acls2public_read(?ACCESS_KEY_0, ?Bucket0),
    {ok, [#bucket_acl_info{user_id = ?GRANTEE_ALL_USER,
                           permissions = [read]}]} = leo_s3_bucket:get_acls(?Bucket0),
    leo_s3_bucket:update_acls2public_read_write(?ACCESS_KEY_0, ?Bucket0),
    {ok, [#bucket_acl_info{user_id = ?GRANTEE_ALL_USER,
                           permissions = [read, write]}]} = leo_s3_bucket:get_acls(?Bucket0),
    leo_s3_bucket:update_acls2authenticated_read(?ACCESS_KEY_0, ?Bucket0),
    {ok, [#bucket_acl_info{user_id = ?GRANTEE_AUTHENTICATED_USER,
                           permissions = [read]}]} = leo_s3_bucket:get_acls(?Bucket0),

    %% Change owner of a bucket
    not_found = leo_s3_bucket:change_bucket_owner(?ACCESS_KEY_2, ?Bucket10),
    ok = leo_s3_bucket:change_bucket_owner(?ACCESS_KEY_2, ?Bucket0),
    {ok, #?BUCKET{name = ?Bucket0,
                  access_key_id = ?ACCESS_KEY_2}} =
        leo_s3_bucket_data_handler:find_by_name({mnesia, ?BUCKET_TABLE}, ?Bucket0),

    application:stop(mnesia),
    timer:sleep(250),
    ok.

ets_suite_(_) ->
    %% preparing
    [] = os:cmd("epmd -daemon"),
    {ok, Hostname} = inet:gethostname(),

    Manager0 = list_to_atom("manager_0@" ++ Hostname),
    net_kernel:start([Manager0, shortnames]),

    {ok, Manager1} = slave:start_link(list_to_atom(Hostname), 'manager_1'),
    true = rpc:call(Manager1, code, add_path, ["../deps/meck/ebin"]),


    %% inspect
    ok = rpc:call(Manager1, meck, new,    [leo_s3_bucket, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, find_buckets_by_id,
                                           fun(_AccessKey, _Checksum) ->
                                                   {ok, match}
                                           end]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, put,
                                           fun(_AccessKey, _Bucket) ->
                                                   ok
                                           end]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, delete,
                                           fun(_AccessKey, _Bucket) ->
                                                   ok
                                           end]),

    ok = rpc:call(Manager1, meck, new,    [leo_s3_auth, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_auth, has_credential,
                                           fun(_AccessKey) ->
                                                   true
                                           end]),


    ok = leo_s3_bucket:start(slave, [Manager1], 3),

    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket0),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket1),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket2),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket3),
    ok = leo_s3_bucket:put(?ACCESS_KEY_0, ?Bucket4),
    ok = leo_s3_bucket:put(?ACCESS_KEY_1, ?Bucket5),
    ok = leo_s3_bucket:put(?ACCESS_KEY_1, ?Bucket6),

    {ok, Ret1} = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_1),
    ?assertEqual(2, length(Ret1)),

    ok = leo_s3_bucket:delete(?ACCESS_KEY_1, ?Bucket5),
    ok = leo_s3_bucket:delete(?ACCESS_KEY_1, ?Bucket6),

    not_found = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_1),
    5 = leo_s3_bucket_data_handler:size({ets, leo_s3_buckets}),

    %% inspect-2
    ok = rpc:call(Manager1, meck, unload, [leo_s3_bucket]),
    ok = rpc:call(Manager1, meck, new,    [leo_s3_bucket, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, find_buckets_by_id,
                                           fun(_AccessKey, _Checksum) ->
                                                   {ok, [#?BUCKET{name = ?Bucket3, access_key_id = ?ACCESS_KEY_0},
                                                         #?BUCKET{name = ?Bucket7, access_key_id = ?ACCESS_KEY_0},
                                                         #?BUCKET{name = ?Bucket8, access_key_id = ?ACCESS_KEY_0}
                                                        ]}
                                           end]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, put,
                                           fun(_AccessKey, _Bucket) ->
                                                   ok
                                           end]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, delete,
                                           fun(_AccessKey, _Bucket) ->
                                                   ok
                                           end]),
    {ok, Ret2} = leo_s3_bucket:find_buckets_by_id(?ACCESS_KEY_0),

    ?assertEqual(3, length(Ret2)),
    3 = leo_s3_bucket_data_handler:size({ets, leo_s3_buckets}),


    %% inspect-3
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, head,
                                           fun(_AccessKey, _Bucket, _Checksum) ->
                                                   {ok, match}
                                           end]),
    ok = leo_s3_bucket:head(?ACCESS_KEY_0, ?Bucket3),

    %% inspect-4
    ok = rpc:call(Manager1, meck, unload, [leo_s3_bucket]),
    ok = rpc:call(Manager1, meck, new,    [leo_s3_bucket, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, head,
                                           fun(_AccessKey, _Bucket, _Checksum) ->
                                                   {ok, #?BUCKET{name = ?Bucket3,
                                                                 access_key_id = ?ACCESS_KEY_0}}
                                           end]),
    ok = leo_s3_bucket:head(?ACCESS_KEY_0, ?Bucket3),

    %% inspect-5
    ok = rpc:call(Manager1, meck, unload, [leo_s3_bucket]),
    ok = rpc:call(Manager1, meck, new,    [leo_s3_bucket, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, head,
                                           fun(_AccessKey, _Bucket, _Checksum) ->
                                                   not_found
                                           end]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, find_buckets_by_id,
                                           fun(_AccessKey, _Checksum) ->
                                                   not_found
                                           end]),

    not_found = leo_s3_bucket:head(?ACCESS_KEY_0, ?Bucket4),
    ?debugVal(ets:tab2list('leo_s3_buckets')),

    %% ACL related
    %% find_bucket_by_name
    ok = rpc:call(Manager1, meck, unload, [leo_s3_bucket]),
    ok = rpc:call(Manager1, meck, new,    [leo_s3_bucket, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, find_bucket_by_name,
                                           fun(_Bucket, _CRC) ->
                                                   {ok, #?BUCKET{name = ?Bucket0,
                                                                 access_key_id = ?ACCESS_KEY_0,
                                                                 acls = [#bucket_acl_info{user_id = ?ACCESS_KEY_0, permissions = [full_control]}]}}
                                           end]),
    %% to be synced
    {ok, [#bucket_acl_info{user_id = ?ACCESS_KEY_0,
                           permissions = [full_control]}]} = leo_s3_bucket:get_acls(?Bucket0),
    %% local records to be refered
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket, find_bucket_by_name,
                                           fun(_Bucket, _CRC) ->
                                                   {ok, #?BUCKET{name = ?Bucket0,
                                                                 access_key_id = ?ACCESS_KEY_0,
                                                                 acls = [#bucket_acl_info{user_id = ?ACCESS_KEY_0, permissions = [read]}]}}
                                           end]),
    {ok, [#bucket_acl_info{user_id = ?ACCESS_KEY_0,
                           permissions = [full_control]}]} = leo_s3_bucket:get_acls(?Bucket0),
    timer:sleep(3500),
    %% to be synced with latest manager's ACL(read)
    {ok, [#bucket_acl_info{user_id = ?ACCESS_KEY_0,
                           permissions = [read]}]} = leo_s3_bucket:get_acls(?Bucket0),


    %% Change owner of a bucket
    ok = rpc:call(Manager1, meck, new,    [leo_s3_bucket_data_handler, [no_link]]),
    ok = rpc:call(Manager1, meck, expect, [leo_s3_bucket_data_handler, insert,
                                           fun(_DBInfo, _BucketData) ->
                                                   ok
                                           end]),
    ok = leo_s3_bucket:change_bucket_owner(?ACCESS_KEY_2, ?Bucket0),

    %% update_providers
    Manager2 = list_to_atom("manager_2@" ++ Hostname),
    ok = leo_s3_bucket:update_providers([Manager2]),

    %% teardown
    slave:stop(Manager1),
    net_kernel:stop(),
    meck:unload(),
    ok.

-endif.

