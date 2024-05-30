defmodule Fluid.AllocationTest do
  @moduledoc """

  Allocate water from pools of equal Pool Rank to tags of equal rank.

  CT of all CTs that tag P1 with tags of equal rank


  Pool Rank - valid only for pools in pps. Refers to the `order` of pools in pps.
  """
  use Fluid.DataCase, async: true
  doctest Fluid.Model.Tag.TagCalculation.Parser
  doctest Fluid.Model

  alias Fluid.Test.Factory
  alias Fluid.Model

  describe "unit tests" do
    test "group pool of same rank from list of pps'es" do
      value =
        # This is a list of pps. each entry in pss indicates a pool
        [~w(r o a b m p z y t q )a, ~w(b g v f s )a, ~w(v f a g h a l uo)a]
        |> Model.group_by_rank()

      assert {10,
              %{
                1 => [:v, :b, :r],
                2 => [:f, :g, :o],
                3 => [:a, :v, :a],
                4 => [:g, :f, :b],
                5 => [:h, :s, :m],
                6 => [:a, :p],
                7 => [:l, :z],
                8 => [:uo, :y],
                9 => [:t],
                10 => [:q]
              }} == value
    end
  end

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

    test "allocations ",
         %{
           circularity_analysis: circularity_analysis,
           warehouses: warehouses,
           pps_analysis_map: pps_analysis_map
         } do
      # find connected capped tanks to a pool
      # since pool belongs to pps => set of capped tanks is same for all pools within pps.

      %{determinate: det_pps_list} = pps_analysis_map

      pps_sets =
        det_pps_list
        |> Enum.map(fn
          %{type: :det_pps_only, pools: pools} ->
            pools
        end)

      assert false
    end
  end
end
