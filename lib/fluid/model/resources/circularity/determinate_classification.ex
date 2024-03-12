defmodule Fluid.Model.Circularity.DeterminateClassification do
  alias Fluid.Model

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
end
