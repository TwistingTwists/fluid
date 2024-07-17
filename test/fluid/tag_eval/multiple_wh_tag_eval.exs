defmodule Fluid.MultiWHTagEvaluationTest do
  use Fluid.DataCase, async: true
  alias Fluid.Model
  alias Fluid.Test.Factory

  describe "pool ranks and tag ranks - scenario 12 July 2024" do
    setup do
      warehouses = Factory.setup_warehouses_for_tag_evaluation(:ranked_pools)

      %{
        circularity_analysis: Model.circularity_analysis(warehouses),
        warehouses: warehouses,
        pps_analysis_map: Model.pps_analysis(warehouses)
      }
    end

    test "pps assertions",
         %{
           circularity_analysis: %{determinate: determinate},
           warehouses: warehouses,
           pps_analysis_map: pps_analysis_map
         } do
      %{determinate: det_pps_list, indeterminate: indet_pps_list, excess_circularity: excess_circularity_pps_list} =
        pps_analysis_map

      assert indet_pps_list == []
      assert excess_circularity_pps_list == []

      assert  [["cp1", "fp1", "fp2", "fp5"]] ==
               det_pps_list
               # |> EncoderHelper.encode_and_store("pps_analysis_map.json")
               |> Enum.map(fn %{pools: pools} -> Enum.map(pools, & &1.name) |> Enum.sort() end)
               |> yellow("det_pps_list")

      # assertions on det_pps_list
      det_pps_list
      |> Enum.map(fn
        %{type: :det_pps_only, related_wh: wh_list} ->
          Enum.map(wh_list, fn wh ->
            # 2. assert that all related_wh are only determinate
            assert Map.has_key?(determinate, wh.id)
          end)

          # 1. assert that type of pps :det_pps_only
          assert true

        val ->
          IO.inspect(val)

          # if type of pps is anything else, assert false
          assert false
      end)
    end
  end

  defp render_assertable(map_or_kv) do
    map_or_kv
    |> Enum.sort_by(fn {pool_id, _alloc} -> pool_id end, :asc)
    |> Enum.flat_map(fn {pool_id, allocations} ->
      Enum.map(allocations, fn vv -> {pool_id, vv.volume, vv.tag_id} end)
    end)
    |> Enum.group_by(
      fn {pool_id, _vol, _tagid} -> Model.Pool.read_by_id!(pool_id).name end,
      fn {_pool_id, vol, tagid} ->
        tag = Model.Tag.read_by_id!(tagid)
        {tag.destination["name"], vol}
      end
    )
    # |> Enum.sort_by(fn {pool_name, {tank_name, tank_alloc}} -> tank_alloc end, :asc)
    |> Enum.map(fn {pool_name, cts_capacity} ->
      {pool_name, Enum.sort_by(cts_capacity, fn {_tank_name, tank_alloc} -> tank_alloc end, :asc)}
    end)
    |> Enum.into(%{})
  end
end
