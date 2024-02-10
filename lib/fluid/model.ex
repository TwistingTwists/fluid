defmodule Fluid.Model do
  @moduledoc """
  Context layer for operating on models
  * World, Warehouse, Tank, Tag
  """
  alias Fluid.Model.Warehouse
  alias Fluid.Model.World
  # alias Common.Results
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank
  alias Fluid.Model.Tag

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

  # add_tank
  # add_pool
  # connect(capped_tank_wh1, capped_pool_wh2)
  # >> Run just the last test
  #

  # def create_tank_standalone(%Fluid.Model.World{} = world, params, opts \\ []) do
  #   params =
  #     params
  #     |> Map.new()
  #     |> dbg()
  #     # |> Map.merge(%{
  #     #   location_type: :standalone,
  #     #   capacity_type: :uncapped
  #     # })
  #     |> Map.merge(%{world: world})

  #   World
  #   |> Ash.Changeset.for_create(:create_tank, params, opts)
  #   |> Fluid.Model.Api.create()
  # end

  # def create_tank_in_warehouse(%Warehouse{} = warehouse, params, opts \\ []) do
  #   params =
  #     params
  #     |> Map.new()
  #     |> Map.merge(%{
  #       location_type: :in_wh
  #       # make no assumption about :capacity_type of tank
  #     })

  #   Warehouse
  #   |> Ash.Changeset.for_create(:udpate_with_tank, warehouse, params, opts)
  #   |> Fluid.Model.Api.create()
  # end

  # def create_pool_in_warehouse(%Warehouse{} = warehouse, params, opts \\ []) do
  #   params =
  #     params
  #     |> Map.new()
  #     |> Map.merge(%{
  #       location_type: :in_wh
  #       # make no assumption about :capacity_type of pool
  #     })

  #   Warehouse
  #   |> Ash.Changeset.for_create(:create_pool, warehouse, params, opts)
  #   |> Fluid.Model.Api.create()
  # end

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

  def add_pools_to_warehouse(%Warehouse{} = warehouse, %Pool{} = pool) do
    add_pools_to_warehouse(warehouse, [pool])
  end

  def add_pools_to_warehouse(warehouse, pools) do
    Enum.reduce_while(pools, nil, fn
      tank, _acc ->
        case Warehouse.add_pool(warehouse, tank) do
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

  @doc """
  # assume: list_of_warehouses = all belong to same world
  # todo iterate over all warehouses.
  #
  """
  def check_circularity(list_of_warehouses) when list_of_warehouses != [] do
    all_tags = Tag.read_all!()
    import Helpers.ColorIO

    for wh <- list_of_warehouses do
      {wh.name, wh.id} |> blue("wh.name")

      tank_ids = Enum.map(wh.tanks, & &1.id)

      inbound_connections =
        Enum.reduce(all_tags, [], fn tag, acc ->
          if tag.source["id"] in tank_ids do
            [tag | acc]
          else
            acc
          end
        end)

      # |> purple("inbound_connections")

      pool_ids = Enum.map(wh.pools, & &1.id)

      # outbound are always from  CP -> CT or UCP -> UCT
      outbound_connections =
        Enum.reduce(all_tags, [], fn tag, acc ->
          if tag.destination["id"] in pool_ids do
            [tag | acc]
          else
            acc
          end
        end)

      # |> orange("outbound_connections")

      {length(inbound_connections), length(outbound_connections)} |> green("\n\n connections: {in, out}")
      # arrow concept?

      is_feeder_node =
        if inbound_connections == [] and length(outbound_connections) >= 1, do: true, else: false

      is_unconnected_node =
        if inbound_connections == [] and outbound_connections == [], do: true, else: false

      is_feeder_node |> purple("is_feeder_node")
      is_unconnected_node |> orange("is_unconnected_node")
    end

    # warehouses =
    #   Enum.reject(list_of_warehouses, fn wh ->
    #     # remove all the feeder_nodes and unconnected_nodes from the world
    #     is_feeder_node || is_unconnected_node
    #   end)

    # run_euler_algorithm(list_of_warehouses)
  end

  def run_euler_algorithm([wh]) do
  end

  def run_euler_algorithm([wh | tail]) do
  end
end
