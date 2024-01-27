defmodule Fluid.Model.World.Calculations.SUCT do
  @moduledoc """
  Count number of SUCT in a world and store them in the struct.

  The module warns if there are tanks of location_type other than :standalone in the world.
  """
  use Ash.Calculation

  require Logger

  # alias Fluid.Repo

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def select(_, opts, _) do
    [opts[:field]]
  end

  @impl true
  def load(_, opts, _) do
    [opts[:field]]
  end

  @impl Ash.Calculation
  def calculate(worlds, opts, _resolution) do
    fields = List.wrap(opts[:field])

    {:ok,
     Enum.map(worlds, fn world ->
       tanks = Kernel.get_in(world, Enum.map(fields, &Access.key/1))
       do_calculate(tanks)
     end)}
  end

  defp do_calculate(tanks) do
    Enum.count(tanks, fn
      %{location_type: :standalone, capacity_type: :uncapped} ->
        1

      tank ->
        Logger.debug(" World has tank :  #{inspect(tank)} ")
        0
    end)
  end
end
