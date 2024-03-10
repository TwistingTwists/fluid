




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
