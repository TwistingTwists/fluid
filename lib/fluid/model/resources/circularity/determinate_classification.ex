defmodule Fluid.Model.Circularity.DeterminateClassification do
  alias Fluid.Model
  alias Fluid.Model.Circularity

  # Determinate classification
  # --------------------------
  def classify_determinate(%{all: _all_wh_list, determinate: determinate_wh_map} = wh_circularity_map) do
    determinate_classified =
      determinate_wh_map
      |> Map.new(fn
        {wh_id, %Circularity{determinate_classes: _determinate_classes, wh: wh} = wh_circularity} ->
          # classify_0 => NO CP / UCP => indirectly means with ONLY FP
          is_class_0? = Circularity.Utils.is_class_0?(wh.pools)

          {wh_id, Circularity.Utils.update_determinate_class_for_wh_circularity(wh_circularity, ?0, is_class_0?)}
      end)
      |> subclassify_further(?0)

    Map.merge(wh_circularity_map, %{determinate: determinate_classified})
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
      for {wh_id, %Circularity{determinate_classes: determinate_classes} = circularity} <- determinate_wh_map,
          prev_class in determinate_classes,
          into: %{} do
        {wh_id, circularity}
      end

    wh_with_prev_class_ids = Enum.map(wh_with_prev_class, fn {wh_id, _circularity} -> wh_id end)

    rest_determinate_wh_map =
      for {wh_id, %Circularity{determinate_classes: []} = circularity} <- determinate_wh_map,
          into: %{} do
        {wh_id, circularity}
      end

    # subclassify rest of the circularity structs
    updated_rest_determinate_wh_map =
      for {wh_id,
           %Circularity{
             wh: wh
           } = wh_circularity} <- rest_determinate_wh_map,
          into: %{} do
        # class 1 = every WH that contains at least one CP and/or UCP, where all of its CPs
        # and UCPs receive water only from one or more WHs of Class 0

        ucp_cp_water_from_prev_class = warehouse_receives_water_from_prev_class?(wh_circularity, wh_with_prev_class_ids)

        # if all ucp_cp of a warehouse receive water from a prev_class => condition is true => we update the circularity struct
        condition = length(ucp_cp_water_from_prev_class) == wh.count_ucp_cp

        {wh_id,
         maybe_update(wh_circularity, condition, fn ->
           Circularity.Utils.update_determinate_class_for_wh_circularity(wh_circularity, prev_class + 1, true)
         end)}
      end

    # remember to return the entire determinate_wh_map by doing Map.merge
    determinate_wh_map = Map.merge(determinate_wh_map, updated_rest_determinate_wh_map)

    # decide whether or not to do further recursion
    if Circularity.Utils.further_subclassify?(updated_rest_determinate_wh_map) do
      subclassify_further(determinate_wh_map, prev_class + 1)
    else
      determinate_wh_map
    end
  end

  defp warehouse_receives_water_from_prev_class?(
         %Model.Circularity{wh: wh, inbound_connections: inbound_connections} = _wh_circularity,
         wh_with_prev_class_ids
       ) do
    Enum.filter(wh.pools, fn
      %{id: pool_id, capacity_type: capacity} when capacity in [:uncapped, :capped] ->
        # a pool may receive water from many sources
        inbound_connections_for_pool =
          Enum.filter(inbound_connections, fn %{destination: %{"id" => pid}} -> pool_id == pid end)

        # every CP / UCP pool must receive water from somewhere.
        if inbound_connections_for_pool == [] do
          false
        else
          Enum.reduce(inbound_connections_for_pool, true, fn %Model.Tag{source: %{"warehouse_id" => source_wh_for_pool}}, acc ->
            has_incoming_from_previous_class? = source_wh_for_pool in wh_with_prev_class_ids
            has_incoming_from_previous_class? && acc
          end)
        end

      %{id: _pool_id} ->
        false
    end)
  end

  defp maybe_update(wh_circularity, false, _update_fn) do
    wh_circularity
  end

  defp maybe_update(_wh_circularity, true, update_fn) do
    update_fn.()
  end
end
