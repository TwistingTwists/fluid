defmodule Fluid.PPS.PPS2WH101 do
  @moduledoc """

  ###########################################################################
  Pool Priority Set:
  Two conditions

  (a) a CT tags more than one pool
  (b) at least one of those tagged pools is tagged by at least one more CT

  Test case diagrams: https://drive.google.com/file/d/16XQDNJEl2TNXePj-UuqhJFhlGr9v9T9g/view?usp=sharing

  contains overlapping pps (2) in one warehouse.
  """

  use Fluid.DataCase, async: true

  alias Fluid.Model
  alias Fluid.Test.Factory

  describe "pps = 1, wh = 1, pps_type = det " do
    setup do
      ###### setup warehouses for circularity  ######
      warehouses = Factory.setup_warehouses_for_circularity(:mix_det_indet)

      [warehouse_1 | rest_wh] = warehouses

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

      [cp_1, cp_2] = warehouse_1.capped_pools
      [fp_1, fp_2] = warehouse_1.fixed_pools

      [ct_1, ct_2, ct_3, ct_4] = warehouse_1.capped_tanks

      # connections inside WH
      {:ok, _} = Fluid.Model.connect(cp_1, ct_1)
      {:ok, _} = Fluid.Model.connect(cp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_2, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_2, ct_3)

      {:ok, _} = Fluid.Model.connect(cp_2, ct_3)
      {:ok, _} = Fluid.Model.connect(cp_2, ct_4)

      # Model.Tag.read_all!()

      ###### update warehouses list!  ######
      updated_warehouses = [warehouse_1 | rest_wh]

      %{
        circularity_analysis: Model.circularity_analysis(updated_warehouses),
        warehouses: updated_warehouses,
        pps_calculated: [[cp_1, fp_1, fp_2, cp_2]],
        pps_analysis_map: Model.pps_analysis(updated_warehouses)
      }

      # main assertions are:
      # 1. assert that type of pps :det_pps_only
      # 2. assert that all related_wh are only determinate
      # 3. assert that all pools in warehouse_1 form a part of pps
    end

    test "pps.type = :det_pps_only - NEGATIVE = (pps_map - indeterminate, excessive_circularity)", %{
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: _det_pps_list, indeterminate: indet_pps_list, excess_circularity: excess_circularity_pps_list} =
        pps_analysis_map

      assert indet_pps_list == []
      assert excess_circularity_pps_list == []
    end

    test "pps.type = :det_pps_only - POSITIVE = ", %{
      # warehouses: warehouses,
      circularity_analysis: %{determinate: determinate},
      pps_calculated: _,
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: det_pps_list, indeterminate: _indet_pps_list, excess_circularity: _} =
        pps_analysis_map

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

    test "pool_count - ", %{
      # circularity_analysis: %{determinate: determinate},
      # pps_calculated: [[cp_1, fp_1 , cp_2, fp_2]]
      pps_analysis_map: pps_analysis_map
    } do
      # there must be two pps from above setup => 2 pools in each pps
      %{determinate: det_pps_list, indeterminate: _indet_pps_list, excess_circularity: _excess_circularity_pps_list} =
        pps_analysis_map

      assert [4] ==
               det_pps_list
               |> Enum.map(fn %{type: :det_pps_only, pools: pools} -> Enum.count(pools) end)
               |> Enum.sort()
    end

    test "pools forming pps - ", %{
      # circularity_analysis: %{determinate: determinate},
      pps_calculated: [[cp_1, fp_1, fp_2, cp_2]],
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: det_pps_list, indeterminate: _, excess_circularity: _} =
        pps_analysis_map

      [pps_1] = det_pps_list

      # cp_1, fp_1 form a pps (either pps_1 or pps_2)
      assert forms_pps?([cp_1, fp_1, fp_2, cp_2], pps_1)
    end
  end

  describe "pps = 1, wh = 1, pps_type = indet " do
    setup do
      ###### setup warehouses for circularity  ######
      warehouses = Factory.setup_warehouses_for_circularity(:mix_det_indet)

      [warehouse_1, warehouse_2 | rest_wh] = warehouses

      {:ok, warehouse_2} =
        Model.add_pools_to_warehouse(
          warehouse_2,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh}
           ]}
        )

      {:ok, warehouse_2} =
        Model.add_tanks_to_warehouse(
          warehouse_2,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh}
           ]}
        )

      [cp_1, cp_2] = warehouse_2.capped_pools
      [fp_1, fp_2] = warehouse_2.fixed_pools

      [ct_1, ct_2, ct_3, ct_4] = warehouse_2.capped_tanks

      # connections inside WH
      {:ok, _} = Fluid.Model.connect(cp_1, ct_1)
      {:ok, _} = Fluid.Model.connect(cp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_2, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_2, ct_3)

      {:ok, _} = Fluid.Model.connect(cp_2, ct_3)
      {:ok, _} = Fluid.Model.connect(cp_2, ct_4)

      # Model.Tag.read_all!()

      ###### update warehouses list!  ######
      updated_warehouses = [warehouse_1, warehouse_2] ++ rest_wh

      %{
        circularity_analysis: Model.circularity_analysis(updated_warehouses),
        warehouses: updated_warehouses,
        pps_calculated: [[cp_1, fp_1, fp_2, cp_2]],
        pps_analysis_map: Model.pps_analysis(updated_warehouses)
      }

      # main assertions are:
      # 1. assert that type of pps :det_pps_only
      # 2. assert that all related_wh are only determinate
      # 3. assert that all pools in warehouse_1 form a part of pps
    end

    test "pps.type = :indet_pps_only - NEGATIVE = (pps_map - determinate, excessive_circularity)", %{
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: det_pps_list, indeterminate: _indet_pps_list, excess_circularity: excess_circularity_pps_list} =
        pps_analysis_map

      assert det_pps_list == []
      assert excess_circularity_pps_list == []
    end

    test "pps.type = :indet_pps_only - POSITIVE = ", %{
      # warehouses: warehouses,
      circularity_analysis: %{indeterminate: indeterminate},
      pps_calculated: _,
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: _det_pps_list, indeterminate: indet_pps_list, excess_circularity: _} =
        pps_analysis_map

      # assertions on indet_pps_list
      indet_pps_list
      |> Enum.map(fn
        %{type: :indet_pps_only, related_wh: wh_list} ->
          Enum.map(wh_list, fn wh ->
            # 2. assert that all related_wh are only determinate
            assert Map.has_key?(indeterminate, wh.id)
          end)

          # 1. assert that type of pps :indet_pps_only
          assert true

        val ->
          IO.inspect(val)

          # if type of pps is anything else, assert false
          assert false
      end)
    end

    test "pool_count - ", %{
      # circularity_analysis: %{determinate: determinate},
      # pps_calculated: [[cp_1, fp_1 , cp_2, fp_2]]
      pps_analysis_map: pps_analysis_map
    } do
      # there must be two pps from above setup => 2 pools in each pps
      %{determinate: _, indeterminate: indet_pps_list, excess_circularity: _excess_circularity_pps_list} =
        pps_analysis_map

      assert [4] ==
               indet_pps_list
               |> Enum.map(fn %{type: :indet_pps_only, pools: pools} -> Enum.count(pools) end)
               |> Enum.sort()
    end

    test "pools forming pps - ", %{
      # circularity_analysis: %{determinate: determinate},
      pps_calculated: [[cp_1, fp_1, fp_2, cp_2]],
      pps_analysis_map: pps_analysis_map
    } do
      %{determinate: _, indeterminate: indet_pps_list, excess_circularity: _} =
        pps_analysis_map

      [pps_1] = indet_pps_list

      assert forms_pps?([cp_1, fp_1, fp_2, cp_2], pps_1)
    end
  end

  # answers the question: `does the given list of pools form a pps?`
  defp forms_pps?(list_of_pools, pps) do
    list_of_pools_id = list_of_pools |> Enum.map(& &1.id) |> Enum.sort() |> Enum.uniq()
    pps_pool_id = pps.pools |> Enum.map(& &1.id) |> Enum.sort() |> Enum.uniq()

    list_of_pools_id == pps_pool_id
  end
end
