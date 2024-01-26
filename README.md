"If your truth sees you cave to the resistance it will not surface."

Tag
1. primary rank
2. secondary rank

warehouse - types
    * feedernode,
    * unconnected node


warehouse - classes
    * determinate -> subclass 0,1,2
    * in determinate -> subclass A,B,C

#### How to test this repo?
1. `mix deps.get `
2. `mix ash_postgres.create`
3. `mix ash_postgres.migrate`
4. `mix test` -- this will only test the test with `@tag :running`. To configure, see `test_helpers.exs`


#### Drop the database if migrations are not working
1. `mix ash_postgres.drop`
2. `mix ash_postgres.create`
3. `mix ash_postgres.migrate`
4. `mix test` -- this will only test the test with `@tag :running`. To configure, see `test_helpers.exs`
