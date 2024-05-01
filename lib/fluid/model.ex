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
  require Logger

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

  ###################### PPS analysis ######################
  # def pps_analysis(%{determinate: det, indeterminate: indet, all: _all} = classified_warehouses) do
  #   Enum.reduce(det, [], fn wh_det, acc  ->

  #    end)
  # end

  # defmodule ABC do
  #   use Ash.Resource

  #   attributes do
  #     attribute(:pools, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Pool]])
  #     attribute(:two_or_more_tagged_pools?, :boolean)
  #   end
  # end

  def pps_analysis(list_of_wh) when list_of_wh != [] do
    all_cts = Enum.flat_map(list_of_wh, & &1.capped_tanks)

    ############### determining PPS is a two step process #####################

    # (a) CT tags more than one pool

    ct_acc =
      for ct <- all_cts, reduce: %{} do
        ct_acc ->
          # ct
          # |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

          {pools, tags} = calculate_inbound_connections_and_pools(ct)
          Map.put(ct_acc, ct.id, %{pools: pools, two_or_more_tagged_pools?: length(tags) >= 2})
      end

    # (b) >= 1  of those tagged pools is tagged by at least one more CT

    ct_id_pps_map =
      for {ct_id, %{pools: pools, two_or_more_tagged_pools?: true} = _ct_acc_map} <- ct_acc, reduce: %{} do
        step_two ->
          # assume: pools don't form pps, hence accumulator is false.
          result =
            Enum.reduce_while(pools, false, fn pool, local_acc ->
              # 1. find all tagged ct
              {cts, _tags} = calculate_outbound_connections_and_cts(pool)
              # 2. check if at least one of cts != ct.id
              if Enum.count(cts, &(&1.id != ct_id)) >= 1 do
                {:halt, true}
              else
                {:cont, local_acc}
              end
            end)

          if result do
            # pools form pps
            pps = Model.PPS.create!(%{pools: pools})
            Map.put(step_two, ct_id, pps)
          else
            step_two
          end
      end

    # Step 1: Collect all pools as a list of lists
    all_pools_list = Enum.map(ct_id_pps_map, fn {_ct_id, pps} -> pps.pools end)

    # Step 2: Create a hashmap to indicate which pools are part of which pool lists
    pool_overlap_map = create_pool_overlap_map(all_pools_list)

    ##########################################
    classify_pps(pool_overlap_map, list_of_wh)
  end

  def create_pool_overlap_map(all_pools_list) do
    Enum.reduce(Enum.with_index(all_pools_list), %{}, fn {pool_list, index}, acc ->
      Enum.reduce(pool_list, acc, fn pool, acc ->
        Map.update(acc, pool.id, [index], &[index | &1])
      end)
    end)
    # Sort the indices for each pool so that it is easier to test
    |> Map.new(fn {pool_id, indices} -> {pool_id, Enum.sort(Enum.uniq(indices))} end)
    |> merge_pool_overlap()
  end

  def merge_pool_overlap(input) do
    input
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      overlapping_keys =
        Enum.filter(acc, fn {_k, v} -> Enum.any?(values, &Enum.member?(v, &1)) end)
        |> Enum.map(fn {k, _v} -> k end)

      merged_values =
        [values | Enum.map(overlapping_keys, fn k -> Map.get(acc, k, []) end)]
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.sort()

      merged_keys = [key | overlapping_keys] |> Enum.sort()

      Enum.reduce(merged_keys, acc, fn k, acc ->
        Map.put(acc, k, merged_values)
      end)
    end)
  end

  def merge_pool_lists(pool_overlap_map, all_pools_list) do
    Enum.reduce(pool_overlap_map, [], fn {_pool_id, indices}, acc ->
      merged_list =
        Enum.reduce(indices, [], fn index, list_acc ->
          list_acc ++ Enum.at(all_pools_list, index)
        end)
        |> List.flatten()
        |> Enum.uniq()

      acc ++ [merged_list]
    end)
    |> Enum.uniq()
  end

  def classify_pps(ct_id_pps_map, list_of_wh) do
    for {_ct_id, pps} <- ct_id_pps_map, reduce: %{determinate: [], indeterminate: [], excess_circularity: []} do
      pps_analysis_map ->
        # 1. perform circularity_analysis of `list_of_wh`
        circularity_analysis = Model.circularity_analysis(list_of_wh)
        # 2. for each pool.warehouse_id in pps.pools, determine the type of circularity for warehouse

        wh_types_for_pools =
          Enum.map(pps.pools, fn pool ->
            warehouse = Model.Warehouse.read_by_id!(pool.warehouse_id)

            cond do
              Map.has_key?(circularity_analysis.indeterminate, warehouse.id) -> :indeterminate
              Map.has_key?(circularity_analysis.determinate, warehouse.id) -> :determinate
            end
          end)

        # 3. on list from  2. -> check if all warehouses are :determinate, :indeterminate or :mixture_of_determinate_indeterminate
        {pps_analysis_category, pps_type} =
          cond do
            Enum.all?(wh_types_for_pools, &(&1 == :indeterminate)) -> {:indeterminate, :indet_pps_only}
            Enum.all?(wh_types_for_pools, &(&1 == :determinate)) -> {:determinate, :det_pps_only}
            true -> {:excess_circularity, :excess_circularity}
          end

        # add `:type` to original pps
        # todo [refactor] : should this be `Model.PPS.update!` ?
        Map.put(pps_analysis_map, pps_analysis_category, [
          %{pps | type: pps_type} | Map.get(pps_analysis_map, pps_analysis_category)
        ])
    end
  end

  # def calculate_inbound_connections(%Model.Tank{} = ct) do
  #   # todo [enhancement]: read tags for world
  #   all_tags = Model.Tag.read_all!()

  #   Enum.reduce(all_tags, [], fn tag, acc ->
  #     if tag.destination["id"] == ct.id do
  #       [tag | acc]
  #     else
  #       acc
  #     end
  #   end)
  # end

  def calculate_inbound_connections_and_pools(%Model.Tank{} = ct) do
    # todo [enhancement]: read tags for world
    all_tags = Model.Tag.read_all!()
    pools_acc = []
    tags_acc = []

    Enum.reduce(all_tags, {pools_acc, tags_acc}, fn tag, {pools_acc, tags_acc} ->
      if tag.destination["id"] == ct.id do
        # assumption that tag.source is pool
        pool = Model.Pool.read_by_id!(tag.source["id"])
        {[pool | pools_acc], [tag | tags_acc]}
      else
        {pools_acc, tags_acc}
      end
    end)
  end

  def calculate_outbound_connections_and_cts(%Model.Pool{} = pool) do
    # todo [enhancement]: read tags for world
    all_tags = Model.Tag.read_all!()
    cts_acc = []
    tags_acc = []

    Enum.reduce(all_tags, {cts_acc, tags_acc}, fn tag, {cts_acc, tags_acc} ->
      if tag.source["id"] == pool.id do
        # assumption that tag.destination is ct
        ct = Model.Tank.read_by_id!(tag.destination["id"])
        {[ct | cts_acc], [tag | tags_acc]}
      else
        {cts_acc, tags_acc}
      end
    end)
  end
end
