alias Fluid.Model.World
alias Fluid.Model.Warehouse
alias Fluid.Model.Pool
alias Fluid.Model.Tank
alias Fluid.Model

#
# {:ok, worlds} = World.read_all()
# world = hd(worlds)

# suct_count = world |> Fluid.Model.Api.load!(:count_standalone_uncapped_tank)

###### ###### ###### ######
# # load function ensures that :tanks is preloaded always.
# world.tanks |> IO.inspect(label: "world.tanks is BEFORE  ")

# tanks_preloaded_in_world =
#   Kernel.get_in(world, Enum.map([opts[:field]], &Access.key/1))
#   |> IO.inspect(label: "tanks_preloaded_in_world ")

# world =
#   if Kernel.is_struct(tanks_preloaded_in_world) do
#     IO.inspect(label: "if block was hit")

#     Fluid.Model.Api.load!(world, opts[:field])
#   else
#     IO.inspect(label: " else block was hit")

#     world
#   end

# world.tanks |> IO.inspect(label: "world.tanks AFTER  ")

# # tanks = world.tanks |> IO.inspect(label: "ensure that world.tanks is loaded?? ")
###### ###### ###### ######
# calculations
alias Fluid.Model.World.Calculations.SUCT

# @impl Ash.Calculation
# def calculate(worlds, opts, _resolution) do
#   {:ok,
#    Enum.map(worlds, fn world ->
#      # load function ensures that :tanks is preloaded always.
#      world.tanks |> IO.inspect(label: "world.tanks is  ")

#      tanks =
#        if %Ash.NotLoaded{} == Kernel.get_in(world, Enum.map([opts[:field]], &Access.key/1)) do
#          Fluid.Model.Api.load!(world, opts[:field])
#          |> IO.inspect(label: "ensure that world.tanks is loaded?? ")
#        else
#          Kernel.get_in(world, Enum.map([opts[:field]], &Access.key/1))
#        end

#      # tanks = world.tanks |> IO.inspect(label: "ensure that world.tanks is loaded?? ")

#      case tanks do
#        [] ->
#          Logger.debug("world: #{world.name} does not have any tanks! ")

#          # no tanks
#          0

#        tanks ->
#          # return the calculation
#          do_calculate(tanks)
#      end
#    end)}
# end

# @impl Ash.Calculation
# def select(_, opts, _) do
#   [opts[:field]]
# end

# @impl Ash.Calculation
# def load(_, opts, _) do
#   [opts[:field]]
# end
