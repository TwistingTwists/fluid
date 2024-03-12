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
    |> preserve_original_connection_list()

    # |> classify_determinate_indeterminate()

    # |> purple("list_of_warehouses")
  end

  def calculate_feeder_and_unconnected_nodes(%{all: list_of_warehouses}) do
    # base case starts with all tags / connections
    all_tags = Tag.read_all!()

    # we start with every warehouse being indeterminate. And keep deleting determinate from that list
    args = %{all: list_of_warehouses, indeterminate: list_of_warehouses, determinate: %{}}

    calculate_feeder_and_unconnected_nodes(args, all_tags)
  end

  def calculate_feeder_and_unconnected_nodes(
        %{all: total_wh, indeterminate: list_of_warehouses, determinate: determinate_wh_map},
        all_tags
      ) do
    {new_wh_acc, tag_acc} =
      for wh <- list_of_warehouses, reduce: {%{}, all_tags} do
        {wh_acc, tag_acc} ->
          inbound_connections = calculate_inbound_connections(wh, all_tags)
          outbound_connections = calculate_outbound_connections(wh, all_tags)

          # arrow concept?
          is_feeder_node =
            if inbound_connections == [] and length(outbound_connections) >= 1,
              do: true,
              else: false

          is_unconnected_node =
            if inbound_connections == [] and outbound_connections == [], do: true, else: false

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
    {after_wh_list, after_tags} =
      for {wh_id, wh_map} <- list_of_warehouses_map, reduce: {list_of_warehouses_map, tags_list} do
        {wh_acc, tags_acc} ->
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

              # delete the feeder nodes
              {Map.delete(wh_acc, wh_id), left_tags}

            %{
              is_feeder_node: false,
              is_unconnected_node: true,
              inbound_connections: _inbound_connections,
              outbound_connections: _outbound_connections
            } ->
              # delete the unconnected nodes
              {Map.delete(wh_acc, wh_id), tags_acc}

            %{is_feeder_node: false, is_unconnected_node: false} ->
              {wh_acc, tags_acc}
          end
      end

    # if wh_id is in indeterminate_circularity list => reject it from determinate_wh_map
    updated_determinate_wh_map =
      Enum.reject(list_of_warehouses_map, fn {wh_id, _wh_map} ->
        if after_wh_list[wh_id] do
          true
        end
      end)
      |> Enum.into(%{})

    determinate_wh_map = Map.merge(determinate_wh_map, updated_determinate_wh_map)

    # determinate_wh_map
    # |> Enum.map(fn {_k, v} -> v.name end)
    # |> yellow("determinate_circularity #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

    # after_wh_list
    # |> Enum.map(fn {_k, v} -> v.name end)
    # |> blue("indeterminate_circularity #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

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

      calculate_feeder_and_unconnected_nodes(warehouse_current_status, after_tags)
      |> run_euler_algorithm()
    else
      %{all: total_wh, indeterminate: after_wh_list, determinate: determinate_wh_map}
    end
  end

  def classify(%{all: _all_wh_map, indeterminate: _indeterminate_wh_map, determinate: _determinate_wh_map} = wh_map) do
    %{determinate: determinate_classified} = classify_determinate(wh_map)
    wh_map = Map.merge(wh_map, %{determinate: determinate_classified})

    %{indeterminate: classified_indeterminate_wh_map} = classify_indeterminate(wh_map)
    Map.merge(wh_map, %{indeterminate: classified_indeterminate_wh_map})
  end

  # Determinate classification 
  # --------------------------

  def classify_determinate(%{all: _all_wh_list, determinate: determinate_wh_map} = wh_circularity_map) do
    determinate_classified =
      determinate_wh_map
      |> Map.new(fn
        {wh_id, %Model.Circularity{determinate_classes: _determinate_classes, wh: wh} = wh_circularity} ->
          # classify_0 => NO CP / UCP => indirectly means with ONLY FP
          is_class_0? =
            Enum.all?(wh.pools, fn
              %{capacity_type: capacity} when capacity not in [:uncapped, :capped] -> true
              _ -> false
            end)

          # add determinate_classes to wh
          wh_circularity =
            if is_class_0? do
              Map.put(wh_circularity, :determinate_classes, [?0] ++ wh_circularity.determinate_classes)
            else
              wh_circularity
            end

          {wh_id, wh_circularity}
      end)
      |> subclassify_further(?0)

    Map.merge(wh_circularity_map, %{determinate: determinate_classified})
  end

  def preserve_original_connection_list(%{all: all, determinate: determinate, indeterminate: indeterminate}) do
    updated_determinate =
      for {wh_id, circularity} <- determinate, into: %{} do
        wh = Model.Warehouse.read_by_id!(wh_id)
        inbound_connections = calculate_inbound_connections(wh)
        outbound_connections = calculate_outbound_connections(wh)
        {wh_id, Map.merge(circularity, %{inbound_connections: inbound_connections, outbound_connections: outbound_connections})}
      end

    updated_indeterminate =
      for {wh_id, circularity} <- indeterminate, into: %{} do
        wh = Model.Warehouse.read_by_id!(wh_id)
        inbound_connections = calculate_inbound_connections(wh)
        outbound_connections = calculate_outbound_connections(wh)
        {wh_id, Map.merge(circularity, %{inbound_connections: inbound_connections, outbound_connections: outbound_connections})}
      end

    %{all: all, determinate: updated_determinate, indeterminate: updated_indeterminate}
  end

  @doc """
  wh_with_prev_class : all wh of prev_class
  prev_class_dest_ids : extract ids from wh_with_prev_class

  rest_determinate_wh_map : determinate_wh_map -- wh_with_prev_class : this map has to be analysed for further classfication

  > Finally, merge both `rest_determinate_wh_map` and `wh_with_prev_class` to return original map
  Map.merge(updated_rest_determinate_wh_map, wh_with_prev_class)

  """
  def subclassify_further(determinate_wh_map, prev_class) do
    wh_with_prev_class =
      for {wh_id, %Model.Circularity{determinate_classes: determinate_classes} = circularity} <- determinate_wh_map,
          prev_class in determinate_classes,
          into: %{} do
        {wh_id, circularity}
      end

    wh_with_prev_class_ids = Enum.map(wh_with_prev_class, fn {wh_id, _circularity} -> wh_id end)

    rest_determinate_wh_map =
      for {wh_id, %Model.Circularity{determinate_classes: []} = circularity} <- determinate_wh_map,
          into: %{} do
        {wh_id, circularity}
      end

    # prev_class_dest_ids =
    #   for {_wh_id, %{outbound_connections: outbound_connections}} <- wh_with_prev_class, into: [] do
    #     Enum.map(outbound_connections, & &1.id)
    #   end

    # subclassify rest of the circularity structs
    updated_rest_determinate_wh_map =
      for {wh_id,
           %Model.Circularity{
             determinate_classes: _determinate_classes,
             wh: wh,
             inbound_connections: inbound_connections
           } = wh_circularity} <- rest_determinate_wh_map,
          into: %{} do
        # inbound_connections
        # |> Enum.map(&tag_to_repr/1)
        # |> green(" #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

        # class 1 = every WH that contains at least one CP and/or UCP, where all of its CPs
        # and UCPs receive water only from one or more WHs of Class 0

        # count_ucp_cp =
        #   Enum.count(wh.pools, fn
        #     %{capacity_type: capacity} when capacity in [:uncapped, :capped] -> true
        #     _ -> false
        #   end)
        count_ucp_cp = wh.count_ucp_cp

        ucp_cp_water_from_prev_class =
          Enum.filter(wh.pools, fn
            %{id: pool_id, capacity_type: capacity} when capacity in [:uncapped, :capped] ->
              # a pool may receive water from many sources
              inbound_connections_for_pool =
                Enum.filter(inbound_connections, fn %{destination: %{"id" => pid}} -> pool_id == pid end)

              # inbound_connections_for_pool
              # |> Enum.map(&tag_to_repr/1)
              # |> green(" #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

              # every CP / UCP pool must receive water from somewhere.
              if inbound_connections_for_pool == [] do
                false
              else
                Enum.reduce(inbound_connections_for_pool, true, fn %Model.Tag{source: %{"warehouse_id" => source_wh_for_pool}},
                                                                   acc ->
                  has_incoming_from_previous_class? = source_wh_for_pool in wh_with_prev_class_ids
                  has_incoming_from_previous_class? && acc
                end)

                # |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
              end

            %{id: _pool_id} ->
              false
          end)

        # |> orange(" #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

        if length(ucp_cp_water_from_prev_class) == count_ucp_cp do
          {wh_id,
           Map.put(
             wh_circularity,
             :determinate_classes,
             [prev_class + 1] ++ wh_circularity.determinate_classes
           )}

          # |> purple("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
        else
          # don't change anything.

          {wh_id, wh_circularity}
        end
      end

    # remember to return the entire determinate_wh_map by doing Map.merge
    determinate_wh_map = Map.merge(determinate_wh_map, updated_rest_determinate_wh_map)

    # decide whether or not to do further recursion
    # if there are empty determinate_classes in any warehouse's circularity struct, => further recursion needed
    further_subclassify? =
      Enum.any?(updated_rest_determinate_wh_map, fn
        {_wh_id,
         %Model.Circularity{
           determinate_classes: []
         }} ->
          true

        _ ->
          false
      end)

    if further_subclassify? do
      # red("calling for further subclassify_further: #{prev_class + 1}")
      subclassify_further(determinate_wh_map, prev_class + 1)
    else
      determinate_wh_map
    end
  end

  # --------------------------
  # --------------------------

  # Indeterminate Classification
  # --------------------------

  def classify_indeterminate(
        %{all: _all_wh_map, determinate: _determinate_wh_map, indeterminate: indeterminate_wh_map} = wh_circularity_map
      )
      when map_size(indeterminate_wh_map) == 0 do
    # for a world where all warehouses are determinate, there is no need for sub classification of indeterminate
    wh_circularity_map
  end

  def classify_indeterminate(
        %{all: _all_wh_map, determinate: determinate_wh_map, indeterminate: indeterminate_wh_map} = wh_circularity_map
      ) do
    determinate_wh_ids = Map.keys(determinate_wh_map)

    indeterminate_classified =
      Map.new(indeterminate_wh_map, fn
        {wh_id,
         %Model.Circularity{inbound_connections: inbound_connections, wh: wh} =
             wh_circularity} ->
          # class A =  every WH that is not of Determinate Class that contains at least one CP and/or UCP that receives water from a WH of Determinate Class
          at_least_one_cp_ucp? =
            Enum.count(wh.pools, fn
              %{capacity_type: capacity} when capacity not in [:uncapped, :capped] -> true
              _ -> false
            end)

          ucp_cp_water_from_determinate? =
            Enum.any?(inbound_connections, fn connection -> connection.source["warehouse_id"] in determinate_wh_ids end)

          # |> brown("ucp_cp_water_from_determinate?: #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

          # # add determinate_classes to wh
          wh_circularity =
            if at_least_one_cp_ucp? >= 1 && ucp_cp_water_from_determinate? do
              # "indeterminate_ A " |> teal("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
              Map.put(wh_circularity, :indeterminate_classes, [?A] ++ wh_circularity.indeterminate_classes)
            else
              wh_circularity
            end

          {wh_id, wh_circularity}
      end)

    # add random warehouse class A if no one has class A based on above rule.
    add_random_class_a? =
      Enum.all?(indeterminate_classified, fn
        {_wh_id, %{indeterminate_classes: []}} -> true
        _ -> false
      end)

    # |> purple("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

    indeterminate_classified =
      if add_random_class_a? do
        # add class A to a random warehouse circularity
        indeterminate_classified_list =
          indeterminate_classified
          |> Enum.sort_by(fn {_k, v} -> v.name end)

        # indeterminate_classified_list
        # |> Enum.map(fn {_k, v} -> v.name end)
        # |> pink(
        #   "************** ************** ************** #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}************** ************** ************** ************** "
        # )

        {wh_id, wh_circularity} = Enum.at(indeterminate_classified_list, 0)
        # wh_id |> purple(" #{wh_circularity.name} is marked class A #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
        # add A to the indeterminate_classes
        wh_circularity = Map.put(wh_circularity, :indeterminate_classes, [?A] ++ wh_circularity.indeterminate_classes)
        Map.put(indeterminate_classified, wh_id, wh_circularity)
      else
        indeterminate_classified
      end

    indeterminate_classified_sub = subclassify_further_indeterminate(indeterminate_classified, ?A)

    # indeterminate_classified_sub
    # |> Enum.sort_by(fn {_k, v } -> v.name end)
    # |> Enum.map(fn {_k, v} -> {v.name, v.indeterminate_classes} end)
    # |> orange(" #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

    # remember to return merged map
    Map.merge(wh_circularity_map, %{indeterminate: indeterminate_classified_sub})
  end

  def subclassify_further_indeterminate(indeterminate_classified, prev_class) do
    wh_with_prev_class =
      for {wh_id, %Model.Circularity{indeterminate_classes: indeterminate_classes} = circularity} <- indeterminate_classified,
          prev_class in indeterminate_classes,
          into: %{} do
        {wh_id, circularity}
      end

    wh_with_prev_class_ids =
      Enum.map(wh_with_prev_class, fn {wh_id, _circularity} -> wh_id end)

    # Enum.map(wh_with_prev_class, fn {_wh_id, circularity} -> circularity.name end)
    # |> teal("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

    rest_indeterminate_wh_map =
      for {wh_id, %Model.Circularity{indeterminate_classes: []} = circularity} <- indeterminate_classified,
          into: %{} do
        {wh_id, circularity}
      end

    # Enum.map(rest_indeterminate_wh_map, fn {_wh_id, circularity} -> circularity.name end)
    # |> pink("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

    updated_rest_determinate_wh_map =
      for {wh_id,
           %Model.Circularity{
             wh: wh,
             inbound_connections: inbound_connections
           } = wh_circularity} <- rest_indeterminate_wh_map,
          into: %{} do
        # inbound_connections
        # |> Enum.map(&tag_to_repr/1)
        # |> green(" #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

        # Class B = every WH that is not of Determinate Class that contains at least one CP and/or UCP 
        # that receives water from a WH of Class A
        # wh.count_ucp_cp |> orange("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

        ucp_cp_water_from_prev_class =
          Enum.filter(wh.pools, fn
            %{id: pool_id, capacity_type: capacity} when capacity in [:uncapped, :capped] ->
              # a pool may receive water from many sources
              inbound_connections_for_pool =
                Enum.filter(inbound_connections, fn %{destination: %{"id" => pid}} -> pool_id == pid end)

              # inbound_connections_for_pool
              # |> Enum.map(&tag_to_repr/1)
              # |> green(" inbound_connections_for_pool #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

              # inbound_connections_for_pool
              # |> Enum.map(fn %{source: %{"warehouse_id" => wh_id}} -> {wh_id, Model.Warehouse.read_by_id!(wh_id).name} end)
              # |> pink(" inbound_connections_for_pool -> source warehouse #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

              # every CP / UCP pool must receive water from somewhere.
              if inbound_connections_for_pool == [] do
                false
              else
                pools =
                  for %Model.Tag{source: %{"warehouse_id" => source_wh_for_pool}} <- inbound_connections_for_pool,
                      source_wh_for_pool in wh_with_prev_class_ids do
                    true
                  end

                # |> purple("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

                length(pools) >= 1
              end

            %{id: _pool_id} ->
              false
          end)

        # |> orange("#{Path.relative_to_cwd(Path.relative_to_cwd(__ENV__.file))}:#{__ENV__.line}")

        # (ucp_cp receives water form prev_class) and (warehouse has >= ucp_cp)
        if length(ucp_cp_water_from_prev_class) >= 1 and wh.count_ucp_cp >= 1 do
          # prev_class + 1
          # |> pink(" indet class: #{wh_circularity.name}: #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

          {wh_id,
           Map.put(
             wh_circularity,
             :indeterminate_classes,
             [prev_class + 1] ++ wh_circularity.indeterminate_classes
           )}

          # |> purple("#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
        else
          # don't change anything.
          # "don't change"
          # |> pink(" indet class: #{wh_circularity.name}: #{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

          {wh_id, wh_circularity}
        end
      end

    # remember to return the entire determinate_wh_map by doing Map.merge
    indeterminate_classified = Map.merge(indeterminate_classified, updated_rest_determinate_wh_map)

    # indeterminate_classified
    # |> Enum.map(fn {_k, v} -> {v.name, v.indeterminate_classes} end)
    # |> red("indeterminate_classified: indeterminate_classes:  #{Path.relative(__ENV__.file)}:#{__ENV__.line}")

    # decide whether or not to do further recursion
    # if there are empty determinate_classes in any warehouse's circularity struct, => further recursion needed
    further_subclassify? =
      Enum.any?(updated_rest_determinate_wh_map, fn
        {_wh_id,
         %Model.Circularity{
           indeterminate_classes: []
         }} ->
          true

        _ ->
          false
      end)

    if further_subclassify? do
      # purple("calling for further subclassify_further: #{prev_class + 1}")
      subclassify_further_indeterminate(indeterminate_classified, prev_class + 1)
    else
      # purple("terminate sub classify: #{prev_class}")
      indeterminate_classified
    end
  end

  def tag_to_repr(%{source: %{"warehouse_id" => in_id}, destination: %{"warehouse_id" => out_id}} = _tag) do
    """
    #{Model.Warehouse.read_by_id!(in_id).name} => #{Model.Warehouse.read_by_id!(out_id).name}
    """
  end

  @doc """
  Given a warehouse, in a world, calculate all the connections 
  todo ensure the world id matches when you read all tags
  """
  def calculate_outbound_connections(%Model.Warehouse{} = wh, all_tags \\ nil) do
    all_tags =
      if all_tags do
        all_tags
      else
        Model.Tag.read_all!()
      end

    tank_ids = Enum.map(wh.tanks, & &1.id)
    pool_ids = Enum.map(wh.pools, & &1.id)
    tank_or_pool_ids = tank_ids ++ pool_ids

    Enum.reduce(all_tags, [], fn tag, acc ->
      if tag.source["id"] in tank_or_pool_ids do
        [tag | acc]
      else
        acc
      end
    end)
  end

  @doc """
  todo ensure the world id matches when you read all tags
  """
  def calculate_inbound_connections(%Model.Warehouse{} = wh, all_tags \\ nil) do
    all_tags =
      if all_tags do
        all_tags
      else
        Model.Tag.read_all!()
      end

    tank_ids = Enum.map(wh.tanks, & &1.id)
    pool_ids = Enum.map(wh.pools, & &1.id)
    tank_or_pool_ids = tank_ids ++ pool_ids

    Enum.reduce(all_tags, [], fn tag, acc ->
      if tag.destination["id"] in tank_or_pool_ids do
        [tag | acc]
      else
        acc
      end
    end)
  end
end
