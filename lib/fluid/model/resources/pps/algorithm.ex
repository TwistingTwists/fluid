defmodule Fluid.Model.Pps.Algorithm do
  @moduledoc """

  Definition of PPS (Pool Priority Set):
  A given PPS exists when:
  (a) a CT tags more than one pool and
  (b) at least one of those tagged pools is tagged by at least one more CT
   When both conditions above are true, all of the pools that are tagged by those CTs
  (including any such pools that are tagged by just one CT) form a PPS

  Algorithm:
  1. Find the CT which tags more than one pool
  2. Find the pool list such that it tags at least one more CT. This is the potential_pps list.
  Upto step 2. , we have ensured that both conditions (a) and (b) are satisified for all the potential_pps_list. Now, to calculate the actual pps, there is one more step involved. The potential pps may share some capped tanks. And thus some of potential_pps may merge to become one bigger pps. This is the role of overlap algo.
  3. Apply Overlap Algo to find the overlapping pool sets


  For example:

  potential_pps_list : [[1,2], [2,3]]
  This means that [1,2] for a pps and [2,3] form a pps. Thus, [1,2,3] form a pps.
  """
  alias Fluid.Model

  ##########################################
  # consolidation algo
  ##########################################
  def consolidated_pools(ct_id_pps_map) do
    # Step 1: Collect all pools as a list of lists
    all_pools_list = Enum.map(ct_id_pps_map, fn {_ct_id, pps} -> pps.pools end)

    # Step 2: Create a hashmap to indicate which pools are part of which pool lists
    all_pools_list
    |> create_pool_overlap_map()
    |> merge_pool_lists(all_pools_list)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {pools, index}, acc ->
      Map.put(acc, index, Model.PPS.create!(%{pools: pools}))
    end)
  end

  ##########################################

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

  ##########################################
  # classfication algo
  ##########################################

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
end
