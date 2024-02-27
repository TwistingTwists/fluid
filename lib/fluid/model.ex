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
  import Helpers.ColorIO

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

  # def connect(%Pool{} = pool, %Tank{} = tank) do
  #   Tag.create(pool, tank)
  # end

  @doc """
  # assume: list_of_warehouses = all belong to same world
  # todo iterate over all warehouses.
  #
  """
  def circularity_analysis(list_of_warehouses) when list_of_warehouses != [] do
    %{all: list_of_warehouses}
    |> calculate_feeder_and_unconnected_nodes
    |> run_euler_algorithm()

    # |> classify_determinate_indeterminate()

    # |> purple("list_of_warehouses")
  end

  def calculate_feeder_and_unconnected_nodes(%{all: list_of_warehouses}) do
    # base case starts with all tags / connections
    all_tags = Tag.read_all!()

    # we start with every warehouse being indeterminate. And keep deleting determinate from that list
    args = %{all: list_of_warehouses, indeterminate: list_of_warehouses, determinate: list_of_warehouses}
    calculate_feeder_and_unconnected_nodes(args, all_tags)
  end

  def calculate_feeder_and_unconnected_nodes(
        %{all: total_wh, indeterminate: list_of_warehouses, determinate: determinate_wh_map},
        all_tags
      ) do
    # "calculate_feeder_and_unconnected_nodes with: all_tags = #{length(all_tags)}) "
    # |> green()

    {new_wh_acc, tag_acc} =
      for wh <- list_of_warehouses, reduce: {%{}, all_tags} do
        {wh_acc, tag_acc} ->
          # {wh.name, wh.id} |> blue("wh.name")

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
          # todo what if two tanks are connected?
          outbound_connections =
            Enum.reduce(all_tags, [], fn tag, acc ->
              # if tag.source["id"] in pool_ids or tag.source["id"] in tank_ids
              if tag.destination["id"] in pool_ids do
                [tag | acc]
              else
                acc
              end
            end)

          # |> orange("outbound_connections")

          # {length(inbound_connections), length(outbound_connections)}
          # |> green("\n\n connections: {in, out}")

          # arrow concept?

          is_feeder_node =
            if inbound_connections == [] and length(outbound_connections) >= 1,
              do: true,
              else: false

          is_unconnected_node =
            if inbound_connections == [] and outbound_connections == [], do: true, else: false

          # is_feeder_node |> purple("is_feeder_node")
          # is_unconnected_node |> orange("is_unconnected_node")

          new_wh_acc =
            Map.put(
              wh_acc,
              wh.id,
              Model.Circularity.create!(%{
                is_feeder_node: is_feeder_node,
                is_unconnected_node: is_unconnected_node,
                outbound_connections: outbound_connections,
                inbound_connections: inbound_connections,
                wh_id: wh.id,
                name: wh.name,
                wh: wh
              })
            )

          {new_wh_acc, tag_acc}
      end

    {%{all: total_wh, indeterminate: new_wh_acc, determinate: determinate_wh_map}, tag_acc}
  end

  # If there are no edges left + if there are some warehouses in indeterminate list => all must be unconnected
  # :up: is not being used directly in the algorithm. But it is implied.

  def run_euler_algorithm({%{all: total_wh, indeterminate: list_of_warehouses_map, determinate: determinate_wh_map}, tags_list}) do
    # when map_size(list_of_warehouses_map) >= 1 do
    {after_wh_list, after_tags} =
      for {wh_id, wh_map} <- list_of_warehouses_map, reduce: {list_of_warehouses_map, tags_list} do
        {wh_acc, tags_acc} ->
          # {wh_map.name, wh_id} |> orange("processing: ")

          # {wh_map.is_feeder_node, wh_map.is_unconnected_node}
          # |> purple(" {wh_map.is_feeder_node, wh_map.is_unconnected_node}")

          case wh_map do
            %{
              is_feeder_node: true,
              is_unconnected_node: false,
              outbound_connections: outbound_connections
            } ->
              # remove all the outbound connections from the warehouse (node)
              outbound_connections_ids = Enum.map(outbound_connections, & &1.id)

              left_tags =
                Enum.reject(tags_acc, fn tag ->
                  tag.id in outbound_connections_ids
                end)

              # IO.puts("\n\n")
              # orange("left_tags: #{length(left_tags)}")

              # delete the feeder nodes
              {Map.delete(wh_acc, wh_id), left_tags}

            %{
              is_feeder_node: false,
              is_unconnected_node: true,
              inbound_connections: _inbound_connections,
              outbound_connections: _outbound_connections
            } ->
              # outbound_connections_ids = Enum.map(outbound_connections, & &1.id)
              # # remove all the outbound connections from the warehouse (node)
              # left_tags =
              #   Enum.reject(tags_acc, fn tag ->
              #     tag.id in outbound_connections_ids
              #   end)

              # IO.inspect(
              #   "\n\n unconnected node: IN = #{Enum.count(inbound_connections)}, OUT = #{Enum.count(outbound_connections)}"
              # )

              # orange("left_tags: #{length(left_tags)}")

              # delete the unconnected nodes
              {Map.delete(wh_acc, wh_id), tags_acc}

            %{is_feeder_node: false, is_unconnected_node: false} ->
              {wh_acc, tags_acc}
          end
      end

    # IO.puts("\n\n")

    # IO.puts(
    #   "Euler Algo: before_ml_map: #{map_size(list_of_warehouses_map)} , after_wl_map: #{map_size(after_wh_list)} "
    # )

    # if wh_id is in indeterminate_circularity list => reject it from determinate_wh_map
    determinate_wh_map =
      Enum.reject(list_of_warehouses_map, fn {wh_id, _wh_map} ->
        if after_wh_list[wh_id] do
          true
        end
      end)
      |> Enum.into(%{})

    # if no nodes were deleted => do not run_euler_algorithm() further
    if map_size(after_wh_list) < map_size(list_of_warehouses_map) do
      indeterminate_wh_list =
        after_wh_list
        |> Enum.map(fn {_wh_id, %{wh: wh}} -> wh end)

      warehouse_current_status = %{
        all: total_wh,
        indeterminate: indeterminate_wh_list,
        determinate: determinate_wh_map
      }

      # {map_size(list_of_warehouses_map), map_size(after_wh_list)}
      # |> yellow("RUNNING AGAIN Euler Algo: {before, after}")

      calculate_feeder_and_unconnected_nodes(warehouse_current_status, after_tags)
      |> run_euler_algorithm()
    else
      # {map_size(list_of_warehouses_map), map_size(after_wh_list)}
      # |> purple("halting Euler Algo: {before, after}")

      %{all: total_wh, indeterminate: after_wh_list, determinate: determinate_wh_map}
    end
  end
    end
  end
end
