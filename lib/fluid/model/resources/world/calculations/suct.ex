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
       do_calculate(world.tanks)
     end)}
  end

  defp do_calculate(tanks) do
    Enum.count(tanks, fn
      %{location_type: :standalone} ->
        1

      tank ->
        Logger.debug(" has tank of location_type:  #{tank.location_type} ")
        0
    end)
  end
end
