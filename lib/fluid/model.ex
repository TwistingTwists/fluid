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

    ##########################################

    Model.Pps.Algorithm.consolidated_pools(ct_id_pps_map)
    |> Model.Pps.Algorithm.classify_pps(list_of_wh)
  end

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

  @doc """
  from a given pool, calculate the {`the capped tanks` , ` outbound connections to capped tanks` }

  This function is used in calculations to yield pps.related_ct
  """
  def calculate_outbound_connections_and_cts(%Model.Pool{} = pool) do
    # todo [enhancement]: read tags for world
    all_tags = Model.Tag.read_all!()
    cts_acc = []
    tags_acc = []

    # Accumulator is a tuple of capped tanks and tags represented as {cts_acc, tag_acc}. Here is the algorithm.
    # 1. start with all_tags in the world
    # 2. if tag's origin is given pool => read tank at the destination of tag
    # 3. accumulate both - the tank and the tag
    Enum.reduce(all_tags, {cts_acc, tags_acc}, fn tag, {cts_acc, tags_acc} ->
      if tag.source["id"] == pool.id do
        # assumption that tag.destination is ct
        # maybe check that as well since a pool could be connected to SUCT
        ct = Model.Tank.read_by_id!(tag.destination["id"])
        {[ct | cts_acc], [tag | tags_acc]}
      else
        {cts_acc, tags_acc}
      end
    end)
  end

  ###########################################################################
  ############### Allocations Module #####################
  ###########################################################################

  @doc """
  iex>  Fluid.Model.group_by_rank([~w(r o a b m p z y t q )a, ~w(b g v f s )a, ~w(v f a g h a l uo)a])
  {10,%{1 => [:v, :b, :r],2 => [:f, :g, :o],3 => [:a, :v, :a],4 => [:g, :f, :b],5 => [:h, :s, :m],6 => [:a, :p],7 => [:l, :z],8 => [:uo, :y],9 => [:t],10 => [:q]}}

  """
  def group_by_rank(list_of_lists) do
    list_of_lists
    |> Enum.reduce({0, %{}}, fn pl, {max_count, acc} ->
      {local_count, sub_map_for_pps} =
        Enum.reduce(pl, {1, acc}, fn pool, {count, local_acc} ->
          existing_pools_of_same_rank = Map.get(acc, count, [])

          {count + 1, Map.put(local_acc, count, [pool] ++ existing_pools_of_same_rank)}
        end)

      max_count = max(max_count, local_count - 1)
      {max_count, sub_map_for_pps}
    end)
  end

  @doc """
  pps_list = list of pool_lists
    each such pool_list forms a pps.

  """

  # def allocate(pps_list) do
  #   # pools - group_by rank
  #   # tags - group_by rank
  #   # allocate from pools of equal rank to tags of equal rank (primary or secondary ranks)
  #   #

  #   {_, pool_by_rank} = pps_list |> Model.group_by_rank()

  #   pool_by_rank |> Enum.map(fn {_rank, pool_list} -> allocate_same_rank_pools(pool_list) end)
  # end

  # @doc """

  # """
  # def allocate_same_rank_pools(pool_list) do
  #   # find related tags
  #   tags_for_pools =
  #     Enum.map(pool_list, fn pool ->
  #       {_cts, tags} = calculate_outbound_connections_and_cts(pool)
  #       tags
  #     end)

  #   # tags - group_by primary rank
  #   # {_, pool_by_rank} =
  #   #   pool_list
  #   #   |> Enum.reduce({0, %{}}, fn pl, {count, acc} -> {count + 1, Map.put(acc, count + 1, pl)} end)
  # end

  def allocations_for_pools(pools) do
    Map.new(pools, fn pool ->
      {pool.id, calculate_allocations(pool)}
    end)
  end

  def calculate_allocations(pool) do
    # find the capped tanks for this pool and their volumes
    # apply the formula
    # emit the tuple of tank_id, allocation

    # todo: can a pool have incoming connections as well?
    # if yes, how to allocate water in that case?
    {cts, outbound_tags} = calculate_outbound_connections_and_cts(pool)

    # Calculate the total residual capacity of all tanks
    total_capacity_of_all_cts = Enum.reduce(cts, 0, fn tank, acc -> acc + tank.residual_capacity end)

    # green({pool.name, Enum.count(cts), Enum.count(outbound_tags)})
    # orange("total_capacity_of_all_cts", total_capacity_of_all_cts)

    # Calculate the volume allocated to each tank using the formula
    allocations =
      Enum.map(cts, fn tank ->
        # Calculate the allocation ratio for the tank
        allocation_ratio =
          Float.round(tank.residual_capacity / total_capacity_of_all_cts, 2)

        # Calculate the volume allocated to the tank
        allocated_volume =
          Float.round(min(pool.volume * 1.0, pool.volume * allocation_ratio), 2)

        # {tank, allocated_volume}
        alloc = update_tag_with_volume({tank, pool, outbound_tags}, allocated_volume)

        alloc
      end)

    allocations
    # {pool, allocations}
  end

  def update_tag_with_volume({tank, pool, tags}, allocated_volume) do
    tag =
      Enum.find(tags, fn tag ->
        tag.source["id"] == pool.id && tag.destination["id"] == tank.id
      end)

    if tag do
      Model.Allocation.create!(%{volume: allocated_volume, tag_id: tag.id})
      # Model.Allocation.create!(%{volume: "#{allocated_volume}", tag_id: tag.id})
    else
      raise "Could not find tag linking the given tank and pool !"
    end
  end

  ########
  # utils
  ########

  ########
  # warehouse
  ########

  def wh_count_uncapped_tank(%Model.Warehouse{count_uncapped_tank: num_uncapped_tank}), do: num_uncapped_tank
  def wh_count_pool(%Model.Warehouse{count_pool: count_pool}), do: count_pool

  def wh_get_tanks(%Model.Warehouse{tanks: tanks}), do: tanks
  def wh_get_pools(%Model.Warehouse{pools: pools}), do: pools




  def in_wh?(tank, %Model.Warehouse{id: warehouse_id}), do: in_wh?(tank, warehouse_id)
  def in_wh?(tank, warehouse_id), do: tank.location_type == :in_wh && tank.warehouse_id == warehouse_id

  @doc """
  Arguments:

  tag
  source warehouse
  destination warehouse

  source and destination can be given in any order.

  Checks whether the tag connects the two given warehouses
  """
  def tag_connects?(
        %Model.Tag{source: %{"warehouse_id" => warehouse_1_id}, destination: %{"warehouse_id" => warehouse_2_id}},
        %Model.Warehouse{id: warehouse_1_id},
        %Model.Warehouse{id: warehouse_2_id}
      ),
      do: true

  def tag_connects?(
        %Model.Tag{source: %{"warehouse_id" => warehouse_1_id}, destination: %{"warehouse_id" => warehouse_2_id}},
        %Model.Warehouse{id: warehouse_2_id},
        %Model.Warehouse{id: warehouse_1_id}
      ),
      do: true

  def tag_connects?(
        %Model.Tag{source: %{"warehouse_id" => warehouse_1_id}, destination: %{"warehouse_id" => warehouse_2_id}},
        warehouse_1_id,
        warehouse_2_id
      ),
      do: true

  def tag_connects?(
        %Model.Tag{source: %{"warehouse_id" => warehouse_1_id}, destination: %{"warehouse_id" => warehouse_2_id}},
        warehouse_2_id,
        warehouse_1_id
      ),
      do: true

  def tag_connects?(_, _, _), do: false
end
