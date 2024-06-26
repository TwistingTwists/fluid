defmodule Fluid.AllocationTest do
  @moduledoc """

  Allocate water from pools of equal Pool Rank to tags of equal rank.

  CT of all CTs that tag P1 with tags of equal rank


  Pool Rank - valid only for pools in pps. Refers to the `order` of pools in pps.
  """
  use Fluid.DataCase, async: true
  # doctest Fluid.Model.Tag.TagCalculation.Parser
  # doctest Fluid.Model

  alias Fluid.Test.Factory
  alias Fluid.Model

  # describe "unit tests" do
  #   test "group pool of same rank from list of pps'es" do
  #     # This is a list of pps. each entry in pss indicates a pool
  #     value =
  #       [~w(r o a b m p z y t q )a, ~w(b g v f s )a, ~w(v f a g h a l uo)a]
  #       |> Model.group_by_rank()

  #     assert {10,
  #             %{
  #               1 => [:v, :b, :r],
  #               2 => [:f, :g, :o],
  #               3 => [:a, :v, :a],
  #               4 => [:g, :f, :b],
  #               5 => [:h, :s, :m],
  #               6 => [:a, :p],
  #               7 => [:l, :z],
  #               8 => [:uo, :y],
  #               9 => [:t],
  #               10 => [:q]
  #             }} == value
  #   end
  # end

  describe "pool and warehouses" do
    setup do
      warehouses = Factory.setup_warehouses_for_allocation(:pool_ct_connections)

      %{
        circularity_analysis: Model.circularity_analysis(warehouses),
        warehouses: warehouses,
        # pps_calculated: [[cp_1, cp_10, fp_11], [cp_2, fp_2, fp_12, cp_13]],
        pps_analysis_map: Model.pps_analysis(warehouses)
      }
    end

    test "allocations for a given pool ",
         %{
           #  circularity_analysis: circularity_analysis,
           warehouses: warehouses
           #  pps_analysis_map: pps_analysis_map
         } do
      # find connected capped tanks to a pool
      # since pool belongs to pps => set of capped tanks is same for all pools within pps.

      # %{determinate: det_pps_list} = pps_analysis_map

      # pools =
      #   det_pps_list
      #   |> Enum.map(fn
      #     %{type: :det_pps_only, pools: pools} ->
      #       pools
      #   end)
      #   |> List.flatten()
      #   |> Enum.uniq()

      pools = Enum.flat_map(warehouses, fn wh -> wh.pools end)

      result =
        pools
        |> Model.allocations_for_pools()
        # |> log( "raw allocations")
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

      # |> blue( "calculate allocations")

      assert %{
               "cp_1" => [{"ct_14", 700.0}, {"ct_1", 1300.0}],
               "cp_10" => [{"ct_14", 100.0}],
               "cp_13" => [{"ct_17", 2000.0}],
               "cp_2" => [{"ct_4", 50.0}, {"ct_17", 60.0}, {"ct_3", 390.0}],
               "fp_1" => [{"ct_2", 2500.0}],
               "fp_11" => [{"ct_14", 100.0}],
               "fp_12" => [{"ct_15", 1215.0}, {"ct_17", 1485.0}],
               "fp_2" => [{"ct_3", 1000.0}]
             } = result

      # also assert the tank along with the volume
    end
  end
end
