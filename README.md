
## module 007 

- pro_rated_a - flow 
- within one warehouse - tagged rank, pool ranks, maybe untagged
- design - pictures 
- 

Todo 

[x] Fluid.Error.ModelError  - warehouse could not be created error 
[x] assert in allocation_test --- include the capped tank to which the volume flows

for each pool that is tagged by more than one ct
    for each ct -> find potential_pps


 %{1 => [0, 2], 2 => [0, 1], 4 => [1], 6 => [2]}

For above input, write a function to  Produce the  following output 

%{1 => [0, 1, 2], 2 => [0, 1,2], 4 => [0,1,2], 6 => [0,1,2]}

Here is the step by step breakdown.

Step 1: 
for key 1, the value is [0,2] => put it in `output`
so, output: %{1 => [0,2] }

Step 2: 
for key 2, the value is [0,1] => search which key in `output` has overlap with any of the values [0,1]. merge all the values for keys where the overlap is present

so, output: %{1 => [0,1,2], => [0, 1,2] }


Step 3: 
for key 4, the value is [1] => search which key in `output` has overlap with any of the values [1]. merge all the values for keys where the overlap is present

so, output: %{1 => [0,1,2], => [0, 1,2], 4 => [0,1,2]  }


Step 4: 
for key 6, the value is [2] => search which key in `output` has overlap with any of the values [2]. merge all the values for keys where the overlap is present

so, output: %{1 => [0, 1, 2], 2 => [0, 1,2], 4 => [0,1,2], 6 => [0,1,2]}


Write an elixir function for given input output pair. 

also genertae 6 tests cases for above


### module 003 - PPS_Order

Yes it is all one PPS. CT2/CP1/FP1/FP2 satisfies (a), and CT3/FP2 satisfies (b). That alone is sufficient to make CP1/FP1/FP2 a single PPS. That PPS is connected to CT3, and since CP2 is also connected to CT3, that makes CP2 part of the same PPS as CP1/FP1/FP2 as well.  So, CP1/FP1/FP2/CP2 is all one PPS.

Tags can most definitely go inter-WH (and therefore pools in different WHs can all be part of the same PPS). At some point I introduced the concept of Virtual Capped Tanks/Pools to handle tags that are inter-WH, but when I drafted the master algorithm I might have abandoned it as unnecessary. Can’t remember; if there’s no reference to Virtual Capped Tanks/Pools in the MA then they’re not needed to deal with inter-WH tags.

Yep all of the pools in WH1 and WH2 form one PPS. The pools in WH1 are one PPS as described above; CP10 and FP11 are incorporated into it via CT14, and FP12 and CT13 are incorporated into it via CT17

* (0) More cases where PPS (usually within same wh)
* (a) Identify PPS : Tag : "Can create a bag_of(PPS) from a world"
    * PPS: set_of(pool) which satisfy two conditions
* (b) bag_of(PPS) has mix of det + indet => "Error (custom) -> UI"
* (c) bag_of(PPS) :  >= 1 PPS with only determinate_wh => eval all module PPS_Eval
* (d) NA : if bag_of(PPS) is all determinate_wh => module c
* (e) NA : if bag_of(PPS) is all indeterminate_wh => module PPS_Eval
* (f) NA : if bag_of(PPS) is all indeterminate_wh => module WH_Order_module

Questions
* Can CT / FP be connected from different WH ?
- how will Pools in PPS contain one WH det and one WH indet?  

<div style="background-color:#2C2C29; padding-top:50px; padding-left:10px;">

Table denoting all possible test cases for module 003: 

| S.No | pps_num | pools_outside_pps | pps_type           | num_wh_involved | remark                |
|------|---------|-------------------|--------------------|-----------------|-----------------------|
| 1    | 0       | 0                 | NA                 |                 |                       |
| 2    | 1       | some              | det                | 1               |                       |
| 3    | 1       | some              | det                | 2               |                       |
| 4    | 1       | some              | indet              | 1               |                       |
| 5    | 1       | some              | indet              | 2               |                       |
| 6    | 1       | some              | excess_circularity | 2               | mix of indet + det wh |
| 7    | 1       | 0                 | det                | 1               |                       |
| 8    | 1       | 0                 | det                | 2               |                       |
| 9    | 1       | 0                 | indet              | 1               |                       |
| 10   | 1       | 0                 | indet              | 2               |                       |
| 11   | 1       | 0                 | excess_circularity | 2               | [ ]                   |
| 12   | 2       | some              | indet              | 1               |                       |
| 13   | 2       | some              | indet              | 2               |                       |
| 14   | 2       | some              | det                | 1               |                       |
| 15   | 2       | some              | det                | 2               |                       |
| 16   | 2       | some              | excess_circularity | 2               |                       |
| 17   | 2       | 0                 | det                | 1               |                       |
| 18   | 2       | 0                 | det                | 2               |                       |
| 19   | 2       | 0                 | indet              | 1               |                       |
| 20   | 2       | 0                 | indet              | 2               |                       |
| 21   | 2       | 0                 | excess_circularity | 2               |                       |


### Here is the meaning of all four columns. 

> You can ignore first column that's just a serial number which denotes the number of rows. 

--- 


1. The second column which is `pps_num`, it indicates how many PPS do you have in the world. 
--- 

2. The third column which is `pool_outside_pps` how many pools are left outside the pool priority set.

> Details:  So, you may have one pool priority set (row 2) and that pool priority set has left out a few pools outside of it.
But if you see row 7, then the pool outside PPS is 0 which means all the pools in the world form a single pool priority set. 

--- 


3. The fourth column which is `pps_type`.  
Now whatever the pool PPS is formed, it may be of three types determinate, indeterminate or excessive circularity. This is based on the type of warehouse involving the PPS. 

> Details: So, PPS may be formed inside a determinate warehouse or among 2-3 warehouses all of them being determinate forming a PPS. 
--- 
 

4.  The last column is `num_wh_involved` (number of warehouse involved) which means that whether you have one warehouse forming the entire PPS or that PPS forms between >1 warehouses. 

> Details: PPS can be formed _entirely_ within one warehouse or it may span more than one warehouses. That is why we have denoted number 2 in `num_wh_involved` (number of warehouse involved) column. 

--- 

#### And with each PPS combination comes 2 other variables which are column 3 (`pools_outside_pps`) and 4 (`pps_type`) . 

Thinking on the combinations provided by column 4 (`pps_type`) -> 

* a. It means that if a PPS is built _entirely_ within one warehouse, then the type of warehouse determines the type of PPS 
* b. In single warehouse you can never have excessive circularity. Since, for excessive circularity, you need a combination of determinate and indeterminate warehouses.
 

Further, column 3 (`pools_outside_pps`) gives us subcases for above `a.` and `b.` -> 
* Z. if a PPS forms within single warehouse, you may have a few pools which are **outside** of PPS, but **inside** warehouse, so 2 more cases are formed as per `some` or `0` in column 2 (`pools_outside_pps`).

_So, considering all these four variables, I think there are 21 cases we need to have diagrams for testing._

</div>


--- 
--- 


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

(a) each `pool` (within a `PPS`) has a Pool Rank (default: 1) or indicated by user -- expand the pool_create api (Pool.create/1)
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
