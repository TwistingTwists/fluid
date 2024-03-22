### module 003 - PPS_Order

* (0) More cases where PPS (usually within same wh)
* (a) Identify PPS : Tag : "Can create a bag_of(PPS) from a world"
    * PPS: set_of(pool) which satisfy two conditions
* (b) bag_of(PPS) has mix of det + indet => "Error (custom) -> UI"
* (c) bag_of(PPS) :  >= 1 PPS with only determinate_wh => eval all module PPS_Eval
* (d) NA : if bag_of(PPS) is all determinate_wh => module c
* (e) NA : if bag_of(PPS) is all indeterminate_wh => module PPS_Eval
* (f) NA : if bag_of(PPS) is all indeterminate_wh => module WH_Order_module


Warehouse Validation 

1. (UCT_empty__regular_CT_not_full) = If any Regular CTs in a WH are not full, then the UCT of that WH must be empty;
2. (regular_CT_full__UCT_filling) =  If all of the Regular CTs in a WH are full, then any remaining water in that WH is distributed to its UCT
3. If that WH has no CTs (Regular or Non-Regular), then all of that WH’s water is distributed to its UCT
4. All Non-Regular CTs must be tagged to one or more pools


World Validation 

1. (start_water_pool_only) = At the beginning of every scenario, all of the water is in pools
2. (no_water_left_in_UCT) = At the end of every scenario, all of the water is in SUCTs and, if there are any CTs in the World, SCTs
3. (conservation_of_water) = The total amount of water in a World at the beginning of a scenario is the same as at the end of that scenario

### module 004 - PPS_Eval

(a) each `pool` (within a `PPS`) has a Pool Rank (default: 1) or indicated by user
(b) all pools (within a `PPS`) => eval all module Tag_Eval


### module 005 - WH_Order

### module 006 -  WH_Eval

### module 007 -  Tag_Eval


### module 008 -  Untagged_water

### module 009 -  Allocation




#### How to test this repo?
1. `mix deps.get `
2. `mix ash_postgres.create`
3. `mix ash_postgres.migrate`
4. for circularity test: use `bash  scripts/circularity_test.sh`


#### Drop the database if migrations are not working
1. `mix ash_postgres.drop`
2. `mix ash_postgres.create`
3. `mix ash_postgres.migrate`
4. `mix test --trace`

### Format of commit message to generate automatic changelog
1. add to mix.exs
    `{:git_ops, "~> 2.6.0", only: [:dev]}`
    * add to dev.exs
    * mix deps.get
2. run `mix git_ops.message_hook`
3. mix git_ops.release --initial
https://gist.github.com/stephenparish/9941e89d80e2bc58a153#format-of-the-commit-message
