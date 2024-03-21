### module 003 

* (0) More cases where PPS (usually within same wh)
    couple of hours.

* (a) PPS: set_of(pool) which satisfy two conditions
    * Tag: from old project
* (b) bag_of(PPS) has mix of det + indet => "Error (custom) -> UI"



* Output: 
    * (a) Identify PPS : Tag : "Can create a bag_of(PPS) from a world"
    
    * (c) >= 1 PPS with only determinate_wh
    * (d) NA : if bag_of(PPS) is all determinate_wh => module c
    * (e) NA : if bag_of(PPS) is all indeterminate_wh => module PPS_Eval
    * (f) NA : if bag_of(PPS) is all indeterminate_wh => module WH_Order_module



### module 004 
input: unordered list of 
output: ordered list of warehouses (PPS)




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
