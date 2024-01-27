defmodule Fluid.Model.Warehouse.Calculations.Pool do
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
  def calculate(warehouses, opts, _resolution) do
    fields = List.wrap(opts[:field])

    {:ok,
     Enum.map(warehouses, fn warehouse ->
       tanks = Kernel.get_in(warehouse, Enum.map(fields, &Access.key/1))
       do_calculate(tanks)
     end)}
  end

  defp do_calculate(tanks) do
    Enum.count(tanks)
  end
end
