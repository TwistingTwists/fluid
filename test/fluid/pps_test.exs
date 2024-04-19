defmodule Fluid.PPSTest do
  @moduledoc """

  ###########################################################################
  Pool Priority Set:
  Two conditions

  (a) a CT tags more than one pool
  (b) at least one of those tagged pools is tagged by at least one more CT

  Test case diagrams: https://drive.google.com/file/d/16XQDNJEl2TNXePj-UuqhJFhlGr9v9T9g/view?usp=sharing
  """

  use Fluid.DataCase, async: true

  alias Fluid.Model
  alias Fluid.Test.Factory

  describe "PPS - all pools form PPS - " do
    # Here are the outcomes expected form the tests for PPS module
    # %Model.PPS{type: :det_indet_both} => invalid! => list_WH
    # %Model.PPS{type: :det_only}] = Map.values(pps_map) => [input: list_pps] PPS_Eval_Module =>  [input: list_wh_det] WH_Order_Module (A)
    # %Model.PPS{type: :indet_only} => [input: list_pps] PPS_Eval_Module =>  [input: list_wh_indet] WH_Order_Module (B, C)

    # assert [
    #   # Error UI
    #   {:excess_circularity, list_wh},
    #   # PPS Evaluation module
    #   {:det_pps_only, list_pps},
    #   # WH ORDER MODULE (A)
    #   {:det_wh, list_wh_D},
    #   # PPS Evaluation module
    #   {:indet_pps_only, list_pps},
    #   # WH ORDER MODULE (B, C)
    #   {:indet_wh, list_wh_F}
    # ]

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

      # warehouse_1 |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
      # connections inside WH
      {:ok, _} = Fluid.Model.connect(cp_1, ct_1)
      {:ok, _} = Fluid.Model.connect(cp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_2, ct_3)

      {:ok, _} = Fluid.Model.connect(cp_2, ct_3)
      {:ok, _} = Fluid.Model.connect(cp_2, ct_4)

      Model.Tag.read_all!()
      # |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

      ###### update warehouses list!  ######
      updated_warehouses = [warehouse_1 | rest_wh]

      %{
        circularity_analysis: Model.circularity_analysis(updated_warehouses),
        warehouses: updated_warehouses,
        pps_calculated: [[cp_1, fp_1], [cp_2, fp_2]],
        pps_analysis_map: Model.pps_analysis(updated_warehouses)
      }
    end

    test "WH = Determinate + pps.type = :det_pps_only - ", %{
      # warehouses: warehouses,
      circularity_analysis: %{determinate: determinate},
      pps_calculated: _,
      pps_analysis_map: pps_analysis_map
    } do
      # main assertions are:
      # 1. assert that type of pps :det_pps_only
      # 2. assert that all related_wh are only determinate
      # 3. assert that all pools in warehouse_1 form a part of pps

      pps_analysis_map
      |> Enum.map(fn
        {_ct_id, %{type: :det_pps_only, related_wh: wh_list}} ->
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

    test "pool_count + pools forming pps - ", %{
      # circularity_analysis: %{determinate: determinate},
      pps_calculated: [[cp_1, fp_1], [cp_2, fp_2]],
      pps_analysis_map: pps_analysis_map
    } do
      # there must be two pps from above setup => 2 pools in each pps
      pps_analysis_map
      # |> dbg()
      |> Enum.map(fn
        {_ct_id, %{type: :det_pps_only, pools: pools}} ->
          assert Enum.count(pools) == 2
      end)

      [pps_1, pps_2] = pps_analysis_map |> Map.values()

      # cp_1, fp_1 form a pps (either pps_1 or pps_2)
      if forms_pps?([cp_1, fp_1], pps_1) do
        refute forms_pps?([cp_1, fp_1], pps_2)
      end

      if forms_pps?([cp_1, fp_1], pps_2) do
        refute forms_pps?([cp_1, fp_1], pps_1)
      end

      # cp_2, fp_2 form a pps (either pps_1 or pps_2)
      if forms_pps?([cp_2, fp_2], pps_1) do
        refute forms_pps?([cp_2, fp_2], pps_2)
      end

      if forms_pps?([cp_2, fp_2], pps_2) do
        refute forms_pps?([cp_2, fp_2], pps_1)
      end
    end

    # test "I -  all pools form PPS - WH Indet ", %{
    #   warehouses: warehouses,
    #   circularity_analysis: %{indeterminate: indeterminate, determinate: determinate}
    # } do
    #   # %{"pps_uuid" => %Model.PPS{}}
    #   pps_map = Model.pps_analysis(warehouses)

    #   assert [%Model.PPS{type: :indet_only}] = Map.values(pps_map)
    #   assert false
    # end

    # test "I -  all pools form PPS - WH mix of Det and Indet ", %{
    #   warehouses: warehouses,
    #   circularity_analysis: %{indeterminate: indeterminate, determinate: determinate}
    # } do
    #   # %{"pps_uuid" => %Model.PPS{}}
    #   pps_map = Model.pps_analysis(warehouses)

    #   assert [%Model.PPS{type: :det_indet_both}] = Map.values(pps_map)
    #   assert false
    # end

    # I - some pools for PPS - WH Det
    # I - some pools for PPS - WH Indet
    # I - some pools for PPS - WH Mix of Det Indet

    # II - pools for PPS - WH Det
    # II - pools for PPS - WH Indet
    # II - pools for PPS - WH Mix of Det Indet

    # 0 - No pools for PPS - WH Det
    # 0 - No pools for PPS - WH Indet
    # 0 - No pools for PPS - WH Mix of Det Indet
  end

  # describe "PPS - all pools form PPS " do
  #   # Here are the outcomes expected form the tests for PPS module
  #   # %Model.PPS{type: :det_indet_both} => invalid! => list_WH
  #   # %Model.PPS{type: :det_only}] = Map.values(pps_map) => [input: list_pps] PPS_Eval_Module =>  [input: list_wh_det] WH_Order_Module (A)
  #   # %Model.PPS{type: :indet_only} => [input: list_pps] PPS_Eval_Module =>  [input: list_wh_indet] WH_Order_Module (B, C)

  #   setup do
  #     ###### setup warehouses for circularity  ######
  #     warehouses = Factory.setup_warehouses_for_circularity(:mix_det_indet)

  #     {[warehouse_1, warehouse_2], rest_wh} = Enum.split(warehouses, 2)

  #     {:ok, warehouse_2} =
  #       Model.add_pools_to_warehouse(
  #         warehouse_2,
  #         {:params,
  #          [
  #            %{capacity_type: :capped, location_type: :in_wh},
  #            %{capacity_type: :capped, location_type: :in_wh},
  #            %{capacity_type: :fixed, location_type: :in_wh},
  #            %{capacity_type: :fixed, location_type: :in_wh}
  #          ]}
  #       )

  #     {:ok, warehouse_2} =
  #       Model.add_tanks_to_warehouse(
  #         warehouse_2,
  #         {:params,
  #          [
  #            %{capacity_type: :capped, location_type: :in_wh},
  #            %{capacity_type: :capped, location_type: :in_wh},
  #            %{capacity_type: :capped, location_type: :in_wh},
  #            %{capacity_type: :capped, location_type: :in_wh}
  #          ]}
  #       )

  #     [cp_1, cp_2] = warehouse_2.capped_pools
  #     [fp_1, fp_2] = warehouse_2.fixed_pools

  #     [ct_1, ct_2, ct_3, ct_4] = warehouse_2.capped_tanks

  #     # warehouse_1 |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
  #     # connections inside WH
  #     {:ok, _} = Fluid.Model.connect(cp_1, ct_1)
  #     {:ok, _} = Fluid.Model.connect(cp_1, ct_2)
  #     {:ok, _} = Fluid.Model.connect(fp_1, ct_2)
  #     {:ok, _} = Fluid.Model.connect(fp_2, ct_3)

  #     {:ok, _} = Fluid.Model.connect(cp_2, ct_3)
  #     {:ok, _} = Fluid.Model.connect(cp_2, ct_4)

  #     Model.Tag.read_all!()
  #     # |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

  #     ###### update warehouses list!  ######
  #     updated_warehouses = [warehouse_1, warehouse_2] ++ rest_wh

  #     %{circularity_analysis: Model.circularity_analysis(updated_warehouses), warehouses: updated_warehouses}
  #   end

  #   test "I -  all pools form PPS - WH Indeterminate ", %{
  #     warehouses: warehouses,
  #     circularity_analysis: %{determinate: determinate}
  #   } do
  #     # there are two main assertions ongoing
  #     # 1. assert that type of pps :indet_pps_only
  #     # 2. assert that all related_wh are only determinate

  #     pps_analysis_map = Model.pps_analysis(warehouses)

  #     pps_analysis_map
  #     |> Enum.map(fn
  #       {_id, %{type: :det_pps_only, related_wh: wh_list}} ->
  #         Enum.map(wh_list, fn wh ->
  #           # 2. assert that all related_wh are only determinate
  #           assert Map.has_key?(determinate, wh.id)
  #         end)

  #         # 1. assert that type of pps :det_pps_only
  #         assert true

  #       val ->
  #         IO.inspect(val)

  #         # if type of pps is anything else, assert false
  #         assert false
  #     end)
  #   end
  # end

  # answers the question: `does the given list of pools form a pps?`
  defp forms_pps?(list_of_pools, pps) do
    list_of_pools_id = list_of_pools |> Enum.map(& &1.id) |> Enum.sort()
    pps_pool_id = pps.pools |> Enum.map(& &1.id) |> Enum.sort()

    list_of_pools_id == pps_pool_id
  end
end
