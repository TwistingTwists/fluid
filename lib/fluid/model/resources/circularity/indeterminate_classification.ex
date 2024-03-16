defmodule Fluid.Model.Circularity.IndeterminateClassification do
  alias Fluid.Model
  # Indeterminate Classification
  # --------------------------

  @doc """
  indeterminate_wh_map is a map with keys as warehouse.id and values as the circularity struct for the warehouse
  i.e. 
  @type indeterminate_wh_map :: %{required(UUID.t()) => Model.Circularity.t()}
  """
  def classify_indeterminate(
        %{all: _all_wh_map, determinate: _determinate_wh_map, indeterminate: indeterminate_wh_map} = wh_circularity_map
      )
      when map_size(indeterminate_wh_map) == 0 do
    # for a world where all warehouses are determinate,
    # i.e. there are no indeterminate warehouses
    #  there is no need for sub classification of indeterminate
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

          ucp_cp_water_from_determinate =
            Enum.count(inbound_connections, fn connection -> connection.source["warehouse_id"] in determinate_wh_ids end)

          wh_circularity =
            Model.Circularity.Utils.update_indeterminate_class_for_wh_circularity(
              wh_circularity,
              ?A,
              ucp_cp_water_from_determinate,
              wh.count_ucp_cp
            )

          {wh_id, wh_circularity}
      end)

    # add random warehouse class A if no one has class A based on above rule.
    add_random_class_a? =
      Enum.all?(indeterminate_classified, fn
        {_wh_id, %{indeterminate_classes: []}} -> true
        _ -> false
      end)

    indeterminate_classified =
      if add_random_class_a? do
        # add class A to a random warehouse circularity
        indeterminate_classified_list = Enum.sort_by(indeterminate_classified, fn {_k, v} -> v.name end)

        {wh_id, wh_circularity} = Enum.at(indeterminate_classified_list, 0)
        # add A to the indeterminate_classes
        wh_circularity = Map.put(wh_circularity, :indeterminate_classes, [?A] ++ wh_circularity.indeterminate_classes)
        Map.put(indeterminate_classified, wh_id, wh_circularity)
      else
        indeterminate_classified
      end

    indeterminate_classified_sub = subclassify_further_indeterminate(indeterminate_classified, ?A)

    # remember to return merged map
    Map.merge(wh_circularity_map, %{indeterminate: indeterminate_classified_sub})
  end

  def subclassify_further_indeterminate(indeterminate_classified, prev_class) do
    # warehouses whose indeterminate_class is given by prev_class. Simple Enum.Filter style
    wh_with_prev_class =
      for {wh_id, %Model.Circularity{indeterminate_classes: indeterminate_classes} = circularity} <- indeterminate_classified,
          prev_class in indeterminate_classes,
          into: %{} do
        {wh_id, circularity}
      end

    wh_with_prev_class_ids =
      Enum.map(wh_with_prev_class, fn {wh_id, _circularity} -> wh_id end)

    rest_indeterminate_wh_map =
      for {wh_id, %Model.Circularity{indeterminate_classes: []} = circularity} <- indeterminate_classified,
          into: %{} do
        {wh_id, circularity}
      end

    updated_rest_determinate_wh_map =
      for {wh_id,
           %Model.Circularity{
             wh: wh
           } = wh_circularity} <- rest_indeterminate_wh_map,
          into: %{} do
        # Class B = every WH that is not of Determinate Class that contains at least one CP and/or UCP 
        # that receives water from a WH of Class A
        ucp_cp_water_from_prev_class = warehouse_receives_water_from_prev_class?(wh_circularity, wh_with_prev_class_ids)

        wh_circularity =
          Model.Circularity.Utils.update_indeterminate_class_for_wh_circularity(
            wh_circularity,
            prev_class + 1,
            ucp_cp_water_from_prev_class,
            wh.count_ucp_cp
          )

        {wh_id, wh_circularity}
      end

    # remember to return the entire determinate_wh_map by doing Map.merge
    indeterminate_classified = Map.merge(indeterminate_classified, updated_rest_determinate_wh_map)

    # decide whether or not to do further recursion
    # if there are empty determinate_classes in any warehouse's circularity struct, => further recursion needed

    if should_further_subclassify?(indeterminate_classified) do
      subclassify_further_indeterminate(indeterminate_classified, prev_class + 1)
    else
      indeterminate_classified
    end
  end

  @doc """
  if no inbound_connections_for_pool => it doesn't receive water from prev_class

  else  
    try to find a pool whose source is in the given list wh_with_prev_class_ids
  """
  def receives_water_from_prev_class?(pool_id, inbound_connections, wh_with_prev_class_ids) do
    Enum.filter(inbound_connections, fn %{destination: %{"id" => pid}} -> pool_id == pid end)
    |> do_receives_water_from_prev_class?(wh_with_prev_class_ids)
  end

  defp do_receives_water_from_prev_class?([] = _inbound_connections_for_pool, _wh_with_prev_class_ids) do
    false
  end

  defp do_receives_water_from_prev_class?(inbound_connections_for_pool, wh_with_prev_class_ids) do
    pools =
      for %Model.Tag{source: %{"warehouse_id" => source_wh_for_pool}} <- inbound_connections_for_pool,
          source_wh_for_pool in wh_with_prev_class_ids do
        true
      end

    length(pools) >= 1
  end

  def warehouse_receives_water_from_prev_class?(
        %Model.Circularity{wh: wh, inbound_connections: inbound_connections} = _wh_circularity,
        wh_with_prev_class_ids
      ) do
    Enum.count(wh.pools, fn
      %{id: pool_id, capacity_type: capacity} when capacity in [:uncapped, :capped] ->
        # a pool may receive water from many sources
        # every CP / UCP pool must receive water from somewhere.
        receives_water_from_prev_class?(pool_id, inbound_connections, wh_with_prev_class_ids)

      %{id: _pool_id} ->
        false
    end)
  end

  def should_further_subclassify?(updated_rest_determinate_wh_map) do
    Enum.any?(updated_rest_determinate_wh_map, fn
      {_wh_id,
       %Model.Circularity{
         indeterminate_classes: []
       }} ->
        true

      _ ->
        false
    end)
  end
end
