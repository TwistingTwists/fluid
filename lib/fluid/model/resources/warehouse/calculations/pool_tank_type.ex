defmodule Fluid.Model.Warehouse.Calculations.PoolorTankType do
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
    tank_or_pool_type = opts[:type]

    {:ok,
     Enum.map(warehouses, fn warehouse ->
       tanks_or_pools = Kernel.get_in(warehouse, Enum.map(fields, &Access.key/1))
       do_filter(tanks_or_pools, tank_or_pool_type)
     end)}
  end

  defp do_filter(tanks_or_pools, tank_or_pool_type) when is_atom(tank_or_pool_type) do
    tanks_or_pools
    |> Enum.filter(fn
      %{capacity_type: ^tank_or_pool_type} -> true
      _ -> false
    end)
  end
end
