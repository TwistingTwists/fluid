defmodule Fluid.Pps.Pps2Wh202Test do
  @moduledoc """

  Diagram
  https://app.diagrams.net/#G1TIIL0REZkxkH1UWt_SvocBORv5PVSUmy#%7B%22pageId%22%3A%22pBqYeYxds1IM3FgU-Hi2%22%7D

  ```graphviz
  digraph connections
  {
  rankdir=LR;

    subgraph cluster_WH1 {
      style=dashed;
      label = "WH1";
      CP1 [shape=box];
      CT1 [shape=box];
      CP2 [shape=box];
      CT4 [shape=box];
      FP1 [shape=box];
      CT2 [shape=box];
      FP2 [shape=box];
      CT3 [shape=box];
    }

    subgraph cluster_WH2 {
      style=dashed;
      label = "WH2";
      CP10 [shape=box];
      CT14 [shape=box];
      CP13 [shape=box];
      CT17 [shape=box];
      FP11 [shape=box];
      CT15 [shape=box];
      FP12 [shape=box];
      CT16 [shape=box];
    }

  CP1 -> CT1;
  CP10 -> CT14;
  FP1 -> CT2;

  CP1 -> CT14;
  FP2 -> CT3;
  CP2 -> CT17;
  FP11 -> CT14;
  FP12 -> CT15;
  FP12 -> CT17;
  CP2 -> CT4;
  CP13 -> CT17;
  }

  ```
  """
  use Fluid.DataCase, async: true

  import Fluid.Test.PpsUtils
  alias Fluid.Model
  alias Fluid.Test.Factory

  # describe "pps = 1 , wh = 2 , pps_type = det" do
  # end

  # describe "pps = 1 , wh = 2 , pps_type = indet" do
  # end

  describe "pps = 1 , wh = 2 , pps_type = determinate, " do
    setup do
      ###### setup warehouses for circularity  ######
      warehouses = Factory.setup_warehouses_for_circularity(:mix_det_indet)

      [warehouse_1 | rest_wh] = warehouses
      warehouse_6 = List.last(rest_wh)

      rest_except_wh_6 = Enum.reject(rest_wh, fn wh -> wh.id == warehouse_6.id end)

      ####################################
      {:ok, warehouse_1} =
        Model.add_pools_to_warehouse(
          warehouse_1,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh}
           ]}
        )

      {:ok, warehouse_1} =
        Model.add_tanks_to_warehouse(
          warehouse_1,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh}
           ]}
        )

      ####################################

      {:ok, warehouse_6} =
        Model.add_pools_to_warehouse(
          warehouse_6,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh}
           ]}
        )

      {:ok, warehouse_6} =
        Model.add_tanks_to_warehouse(
          warehouse_6,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh}
           ]}
        )

      ####################################

      [cp_1, cp_2] = warehouse_1.capped_pools
      [fp_1, fp_2] = warehouse_1.fixed_pools

      [ct_1, ct_2, ct_3, ct_4] = warehouse_1.capped_tanks

      ####################################

      [cp_10, cp_13] = warehouse_6.capped_pools
      [fp_11, fp_12] = warehouse_6.fixed_pools

      [ct_14, ct_15, _ct_16, ct_17] = warehouse_6.capped_tanks

      ####################################
      # connections inside WH1
      {:ok, _} = Fluid.Model.connect(cp_1, ct_1)

      {:ok, _} = Fluid.Model.connect(fp_1, ct_2)

      {:ok, _} = Fluid.Model.connect(fp_2, ct_3)

      {:ok, _} = Fluid.Model.connect(cp_2, ct_3)
      {:ok, _} = Fluid.Model.connect(cp_2, ct_4)

      ####################################
      # connections inside WH2
      {:ok, _} = Fluid.Model.connect(cp_10, ct_14)
      {:ok, _} = Fluid.Model.connect(fp_11, ct_14)

      {:ok, _} = Fluid.Model.connect(fp_12, ct_15)
      {:ok, _} = Fluid.Model.connect(fp_12, ct_17)

      {:ok, _} = Fluid.Model.connect(cp_13, ct_17)

      ####################################
      # connections between WH1 and WH2
      {:ok, _} = Fluid.Model.connect(cp_2, ct_17)
      {:ok, _} = Fluid.Model.connect(cp_1, ct_14)

      ####################################
      ###### update warehouses list!  ######
      updated_warehouses = ([warehouse_1, rest_except_wh_6] ++ [warehouse_6]) |> List.flatten()

      assert updated_warehouses |> Enum.map(& &1.id) == warehouses |> Enum.map(& &1.id)

      %{
        circularity_analysis: Model.circularity_analysis(updated_warehouses),
        warehouses: updated_warehouses,
        pps_calculated: [[cp_1, cp_10, fp_11], [cp_2, fp_2, fp_12, cp_13]],
        pps_analysis_map: Model.pps_analysis(updated_warehouses)
      }
    end

    test "pps.type = determinate - NEGATIVE ", %{
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: _, indeterminate: indet_pps_list, excess_circularity: excess_circularity_pps_list} =
        pps_analysis_map

      assert excess_circularity_pps_list == []
      assert indet_pps_list == []
    end

    test "pps.type = determinate - POSITIVE ", %{
      pps_analysis_map: pps_analysis_map,
      circularity_analysis: %{determinate: determinate, indeterminate: _indeterminate}
    } do
      %{determinate: det_pps_list, indeterminate: _, excess_circularity: _} =
        pps_analysis_map

      det_pps_list
      |> Enum.map(fn
        %{type: :det_pps_only, related_wh: wh_list} ->
          assert Enum.count(wh_list, fn wh -> Map.has_key?(determinate, wh.id) end) >= 1

        # since there is at least one determinate and at least one indeterminate related_wh to the pps => excess_circularity

        val ->
          IO.inspect(val)

          # if type of pps is anything else, assert false
          assert false
      end)

      # total pps are two in det_pps_list
      assert Enum.count(det_pps_list) == 2
    end

    test "pool_count - ", %{
      # circularity_analysis: %{determinate: determinate},
      # pps_calculated: [[cp_1, fp_1], [cp_2, fp_2]],
      pps_analysis_map: pps_analysis_map
    } do
      # there must be two pps from above setup => 3 pools in each pps
      %{determinate: det_pps_list, indeterminate: _indet_pps_list, excess_circularity: _excess_circularity_pps_list} =
        pps_analysis_map

      assert [3, 4] ==
               det_pps_list
               |> Enum.map(fn
                 %{type: :det_pps_only, pools: pools} ->
                   Enum.count(pools)
               end)
               |> Enum.sort()
    end

    test "pools forming pps - ", %{
      # circularity_analysis: %{determinate: determinate},
      pps_calculated: [[cp_1, cp_10, fp_11], [cp_2, fp_2, fp_12, cp_13]],
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: det_pps_list, indeterminate: _, excess_circularity: _excess_circularity_pps_list} =
        pps_analysis_map

      assert [_pps_1, _pps_2] = det_pps_list

      # # [cp_1, cp_10, fp_11] form a pps (either pps_1 or pps_2)
      assert forms_pps_either?([cp_1, cp_10, fp_11], det_pps_list)

      # [cp_2, fp_2, fp_12, cp_13] form a pps (either pps_1 or pps_2)
      assert forms_pps_either?([cp_2, fp_2, fp_12, cp_13], det_pps_list)
    end
  end
end
