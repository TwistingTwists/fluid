defmodule Fluid.Model do
  @moduledoc """
  Context layer for operating on models
  * World, Warehouse, Tank, Tag
  """
  alias __MODULE__
  alias Fluid.Model.Warehouse
  # alias Fluid.Model.World
  # alias Common.Results
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank
  alias Fluid.Model.Tag
  # import Helpers.ColorIO

  def create_world(params, opts \\ []) do
    # it is important to convert `params` to map and `opts` to be a keyword list
    # https://hexdocs.pm/ash/code-interface.html#using-the-code-interface
    params = Map.new(params)

    Fluid.Model.World
    |> Ash.Changeset.for_create(:create, params, opts)
    |> Fluid.Model.Api.create()

    # |> Results.wrap()
  end

  # TODO relate warehouse to a world. as of now, all warehouses do not belong to a world
  def create_warehouse(params, opts \\ []) do
    params = Map.new(params)

    Warehouse
    |> Ash.Changeset.for_create(:create, params, opts)
    |> Fluid.Model.Api.create()
    |> or_error("warehouse")

    # |> dbg()
    # |> Results.wrap()
  end

  def or_error({:ok, val}, _target), do: {:ok, val}

  def or_error({:error, error}, target) do
    {:error, Fluid.Error.ModelError.exception(error: error, target: target)}
  end

  def add_tanks_to_warehouse(%Warehouse{} = warehouse, {:params, tank_opts})
      when is_list(tank_opts) do
    tanks =
      Enum.map(tank_opts, fn tank_option ->
        Model.Tank.create!(tank_option)
      end)

    add_tanks_to_warehouse(warehouse, tanks)
  end

  def add_tanks_to_warehouse(%Warehouse{} = warehouse, %Tank{} = tank) do
    add_tanks_to_warehouse(warehouse, [tank])
  end

  def add_tanks_to_warehouse(warehouse, tanks) do
    Enum.reduce_while(tanks, nil, fn
      tank, _acc ->
        case Warehouse.add_tank(warehouse, tank) do
          {:ok, updated_warehouse} ->
            {:cont, {:ok, updated_warehouse}}

          {:error, error} ->
            {:halt, {:error, error}}
        end
    end)
  end

  def add_pools_to_warehouse(%Warehouse{} = warehouse, {:params, pool_opts})
      when is_list(pool_opts) do
    pools =
      Enum.map(pool_opts, fn pool_option ->
        Model.Pool.create!(pool_option)
      end)

    add_pools_to_warehouse(warehouse, pools)
  end

  def add_pools_to_warehouse(%Warehouse{} = warehouse, %Pool{} = pool) do
    add_pools_to_warehouse(warehouse, [pool])
  end

  def add_pools_to_warehouse(warehouse, pools) do
    Enum.reduce_while(pools, nil, fn
      pool, _acc ->
        case Warehouse.add_pool(warehouse, pool) do
          {:ok, updated_warehouse} ->
            {:cont, {:ok, updated_warehouse}}

          {:error, error} ->
            {:halt, {:error, error}}
        end
    end)
  end

  def connect(%Tank{} = tank, %Pool{} = pool) do
    Tag.create(tank, pool)
  end

  def connect(%Pool{} = pool, %Tank{} = tank) do
    Tag.create_reverse(pool, tank)
  end

  @doc """
  # todo ensure list_of_warehouses = all belong to same world
  """
  def circularity_analysis(list_of_warehouses) when list_of_warehouses != [] do
    %{all: list_of_warehouses}
    |> Model.Circularity.calculate_feeder_and_unconnected_nodes()
    |> Model.Circularity.run_euler_algorithm()
    # since euler algorithm requires to delete the outbound connections from feeder nodes,
    # we ensure that original tags are restored after euler algorithm
    |> Model.Circularity.Utils.preserve_original_connection_list()
  end

  def classify(%{all: _all_wh_map, indeterminate: _indeterminate_wh_map, determinate: _determinate_wh_map} = wh_map) do
    wh_map
    |> Model.Circularity.DeterminateClassification.classify_determinate()
    |> Model.Circularity.IndeterminateClassification.classify_indeterminate()
  end

  ######## PPS analysis ########
  # def pps_analysis(%{determinate: det, indeterminate: indet, all: _all} = classified_warehouses) do
  #   Enum.reduce(det, [], fn wh_det, acc  ->

  #    end)
  # end

  def pps_analysis(list_of_wh) when list_of_wh != [] do
    all_cts = Enum.map(list_of_wh, & &1.capped_tanks)

    # determining PPS is a two step process
    # (a) CT tags more than one pool

    for ct <- all_cts do
      calculate_inbound_connections(ct)
    end

    # (b) >= 1  of those tagged pools is tagged by at least one more CT
  end

  def calculate_inbound_connections(%Model.Tank{} = ct) do
    all_tags = Model.Tag.read_all!()

    Enum.reduce(all_tags, [], fn tag, acc ->
      if tag.destination["id"] == ct.id do
        [tag | acc]
      else
        acc
      end
    end)
  end
end
