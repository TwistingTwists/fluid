defmodule Fluid.TagEvaluationTest do
  use Fluid.DataCase, async: true
  alias Fluid.Model
  alias Fluid.Test.Factory

  describe "pool and warehouses" do
    setup do
      warehouses = Factory.setup_warehouses_for_tag_evaluation()

      %{
        circularity_analysis: Model.circularity_analysis(warehouses),
        warehouses: warehouses,
        pps_analysis_map: Model.pps_analysis(warehouses)
      }
    end

    test "A0",
         %{
           # circularity_analysis: Model.circularity_analysis(warehouses),
           warehouses: warehouses
           # pps_analysis_map: Model.pps_analysis(warehouses)
         } do
      # diagram
      # https://app.diagrams.net/#G1PMxG2ThdrB5xfoWo2SnVc_DZj3IYF4OE#%7B%22pageId%22%3A%22pBqYeYxds1IM3FgU-Hi2%22%7D

      pools = Enum.flat_map(warehouses, fn wh -> wh.pools end)

      result =
        pools
        |> Model.allocations_for_pools()
        |> render_assertable()

      # %{
      #   "fp1" => [{"ct1", 215.0}, {"ct3", 285.0}],
      #   "fp2" => [{"ct1", 129.0}, {"ct3", 171.0}, {"ct2", 300.0}],
      #   "fp3" => [{"ct1", 86.0}, {"ct3", 114.0}, {"ct2", 200.0}],
      #   "fp4" => [{"ct2", 164.0}, {"ct3", 236.0}]
      # }

      transformed_data =
        Enum.reduce(result, %{}, fn {_, values}, acc ->
          Enum.reduce(values, acc, fn {key, value}, acc ->
            Map.update(acc, key, value, fn existing_value -> existing_value + value end)
          end)
        end)
        |> log()

      assert %{"ct1" => 215.0, "ct2" => 664.0, "ct3" => 521.0} = transformed_data
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
