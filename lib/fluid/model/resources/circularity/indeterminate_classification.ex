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
end
