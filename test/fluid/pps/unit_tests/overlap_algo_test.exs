defmodule Fluid.Model.OverlapAlgoTest do
  @doc """

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
  use ExUnit.Case

  alias Fluid.Model.Pps.Algorithm

  test "pool_overlap_map with single pool list" do
    all_pools_list = [[%{name: "pool1", id: 1}, %{name: "pool2", id: 2}, %{name: "pool3", id: 3}]]

    pool_overlap_map = Algorithm.create_pool_overlap_map(all_pools_list)
    merged_lists = Algorithm.merge_pool_lists(pool_overlap_map, all_pools_list)

    assert pool_overlap_map == %{1 => [0], 2 => [0], 3 => [0]}
    assert merged_lists == [[%{name: "pool1", id: 1}, %{name: "pool2", id: 2}, %{name: "pool3", id: 3}]]
  end

  test "pool_overlap_map with multiple pool lists - forming multiple PPS - same as original list" do
    # all_pools_list represents the pools that maybe form a pps. these are calculations per capped tank.
    # so, the overlapping pools need to be merged to create a final pps.
    all_pools_list = [
      [%{name: "pool1", id: 1}, %{name: "pool2", id: 2}],
      [%{name: "pool3", id: 3}, %{name: "pool4", id: 4}],
      [%{name: "pool5", id: 5}, %{name: "pool6", id: 6}]
    ]

    pool_overlap_map = Algorithm.create_pool_overlap_map(all_pools_list)
    merged_lists = Algorithm.merge_pool_lists(pool_overlap_map, all_pools_list)

    assert pool_overlap_map == %{1 => [0], 2 => [0], 3 => [1], 4 => [1], 5 => [2], 6 => [2]}

    assert merged_lists == [
             [%{name: "pool1", id: 1}, %{name: "pool2", id: 2}],
             [%{name: "pool3", id: 3}, %{name: "pool4", id: 4}],
             [%{name: "pool5", id: 5}, %{name: "pool6", id: 6}]
           ]
  end

  test "pool_overlap_map with multiple pool lists - forming one PPS" do
    all_pools_list = [
      [%{name: "pool1", id: 1}, %{name: "pool2", id: 2}],
      [%{name: "pool2", id: 2}, %{name: "pool4", id: 4}],
      [%{name: "pool1", id: 1}, %{name: "pool6", id: 6}]
    ]

    pool_overlap_map = Algorithm.create_pool_overlap_map(all_pools_list)
    merged_lists = Algorithm.merge_pool_lists(pool_overlap_map, all_pools_list)

    assert pool_overlap_map == %{1 => [0, 1, 2], 2 => [0, 1, 2], 4 => [0, 1, 2], 6 => [0, 1, 2]}

    assert merged_lists == [
             [
               %{name: "pool1", id: 1},
               %{name: "pool2", id: 2},
               %{name: "pool4", id: 4},
               %{name: "pool6", id: 6}
             ]
           ]
  end

  test "pool_overlap_map with multiple pool lists - forming multiple PPS - different than original list" do
    # all_pools_list represents the pools that maybe form a pps. these are calculations per capped tank.
    # so, the overlapping pools need to be merged to create a final pps.
    all_pools_list = [
      [%{name: "pool1", id: 1}, %{name: "pool2", id: 2}],
      [%{name: "pool2", id: 2}, %{name: "pool4", id: 4}],
      [%{name: "pool5", id: 5}, %{name: "pool6", id: 6}]
    ]

    pool_overlap_map = Algorithm.create_pool_overlap_map(all_pools_list)
    merged_lists = Algorithm.merge_pool_lists(pool_overlap_map, all_pools_list)

    assert pool_overlap_map == %{1 => [0, 1], 2 => [0, 1], 4 => [0, 1], 5 => [2], 6 => [2]}

    assert merged_lists == [
             [%{name: "pool1", id: 1}, %{name: "pool2", id: 2}, %{name: "pool4", id: 4}],
             [%{name: "pool5", id: 5}, %{name: "pool6", id: 6}]
           ]
  end

  test "pool_overlap_map with empty pool list" do
    all_pools_list = []
    pool_overlap_map = Algorithm.create_pool_overlap_map(all_pools_list)
    merged_lists = Algorithm.merge_pool_lists(pool_overlap_map, all_pools_list)
    assert merged_lists == []
    assert pool_overlap_map == %{}
  end
end
