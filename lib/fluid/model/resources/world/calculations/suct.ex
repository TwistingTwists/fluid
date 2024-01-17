defmodule Fluid.Model.World.Calculations.SUCT do
  @moduledoc """
  Count number of SUCT in a world and store them in the struct.

  The module warns if there are tanks of location_type other than :standalone in the world.
  """
  use Ash.Calculation

  import Ecto.Query
  require Logger

  alias Fluid.Repo

  @impl true
  def init(opts) do
    opts |> IO.inspect(label: " init/1 in calculation.suct -> opts are ->")

    {:ok, opts}
  end

  @impl true
  def select(_, opts, _) do
    [opts[:field]]
  end

  @impl true
  def load(_, opts, _) do
    opts |> IO.inspect(label: " load/3 in calculation.suct -> opts are ->")

    [opts[:field]]
  end

  @impl Ash.Calculation
  def calculate(worlds, opts, _resolution) do
    {:ok,
     Enum.map(worlds, fn world ->
       case world.tanks do
         [] ->
           Logger.debug("world: #{world.name} does not have any tanks! ")

           # no tanks
           0

         tanks ->
           # return the calculation
           world |> IO.inspect(label: " world is loaded. ", struct: false)

           tanks
           |> IO.inspect(
             label: "you can going to do enum.reduce. is tanks a list? ",
             struct: false
           )

           do_calculate(tanks)
       end
     end)}
  end

  defp do_calculate(tanks) do
    IO.inspect("inside do_calculate funtion now : and value received is ")
    IO.inspect(tanks)

    Enum.reduce(tanks, 0, fn
      %{location_type: :standalone}, acc ->
        acc + 1

      tank, acc ->
        Logger.debug(" has tank of location_type:  #{tank.location_type} ")
        acc
    end)
  end
end
