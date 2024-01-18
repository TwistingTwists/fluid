:erlang.system_flag(:backtrace_depth, 100)
ExUnit.configure(exclude: [tested: false], include: [testing: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Fluid.Repo, :manual)
