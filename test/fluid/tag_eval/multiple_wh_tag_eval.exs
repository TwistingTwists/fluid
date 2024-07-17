defmodule Fluid.MultiWHTagEvaluationTest do
  use Fluid.DataCase, async: true
  alias Fluid.Model
  alias Fluid.Test.Factory

  describe "pool ranks and tag ranks" do
    setup do
      warehouses = Factory.setup_warehouses_for_tag_evaluation(:ranked_pools)

      %{
        circularity_analysis: Model.circularity_analysis(warehouses),
        warehouses: warehouses,
        pps_analysis_map: Model.pps_analysis(warehouses)
      }
    end

    test "scenario 12 July 2024",
         %{
           circularity_analysis: circularity_analysis,
           warehouses: warehouses,
           pps_analysis_map: pps_analysis_map
         } do
      pps_analysis_map |> purple("pps_analysis_map")
      circularity_analysis |> yellow("circularity_analysis")

      # assert false
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
