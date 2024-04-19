defmodule Fluid.PPS.AllPoolPps do
  @moduledoc """

  ###########################################################################
  Pool Priority Set:
  Two conditions

  (a) a CT tags more than one pool
  (b) at least one of those tagged pools is tagged by at least one more CT

  Test case diagrams: https://drive.google.com/file/d/16XQDNJEl2TNXePj-UuqhJFhlGr9v9T9g/view?usp=sharing


  Total number of possible test cases:
    - number of pps in world = 0 , 1 , > 1
    - pools form pps = all / some
    - pps.type = :det_pps_only / :indet_pps_only / :excessive_circularity


  # tests variations included in this test module : test_case 17-21 in README.md
  > warehouses - 1, 2
  > pps_type - Model.PPS.PPSTypes

  """

  use Fluid.DataCase, async: true

  alias Fluid.Model
  alias Fluid.Test.Factory

  describe "pps = 2, popps = 0, wh = 1 " do
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

      # connections inside WH
      {:ok, _} = Fluid.Model.connect(cp_1, ct_1)
      {:ok, _} = Fluid.Model.connect(cp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_1, ct_2)
      {:ok, _} = Fluid.Model.connect(fp_2, ct_3)

      {:ok, _} = Fluid.Model.connect(cp_2, ct_3)
      {:ok, _} = Fluid.Model.connect(cp_2, ct_4)

      Model.Tag.read_all!()

      ###### update warehouses list!  ######
      updated_warehouses = [warehouse_1 | rest_wh]

      %{
        circularity_analysis: Model.circularity_analysis(updated_warehouses),
        warehouses: updated_warehouses,
        pps_calculated: [[cp_1, fp_1], [cp_2, fp_2]],
        pps_analysis_map: Model.pps_analysis(updated_warehouses)
      }

      # main assertions are:
      # 1. assert that type of pps :det_pps_only
      # 2. assert that all related_wh are only determinate
      # 3. assert that all pools in warehouse_1 form a part of pps
    end

    test "wh = determinate + pps.type = :det_pps_only - ", %{
      # warehouses: warehouses,
      circularity_analysis: %{determinate: determinate},
      pps_calculated: _,
      pps_analysis_map: pps_analysis_map
    } do
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

    test "pool_count - ", %{
      # circularity_analysis: %{determinate: determinate},
      # pps_calculated: [[cp_1, fp_1], [cp_2, fp_2]],
      pps_analysis_map: pps_analysis_map
    } do
      # there must be two pps from above setup => 2 pools in each pps
      pps_analysis_map
      |> Enum.map(fn
        {_ct_id, %{type: :det_pps_only, pools: pools}} ->
          assert Enum.count(pools) == 2
      end)
    end

    test "pools forming pps - ", %{
      # circularity_analysis: %{determinate: determinate},
      pps_calculated: [[cp_1, fp_1], [cp_2, fp_2]],
      pps_analysis_map: pps_analysis_map
    } do
      [pps_1, pps_2] = pps_analysis_map |> Map.values()

      # cp_1, fp_1 form a pps (either pps_1 or pps_2)
      case {forms_pps?([cp_1, fp_1], pps_1), forms_pps?([cp_1, fp_1], pps_2)} do
        {true, false} ->
          assert true

        {false, true} ->
          assert true

        incorrect ->
          IO.inspect(incorrect)
          assert false
      end

      # cp_2, fp_2 form a pps (either pps_1 or pps_2)
      case({forms_pps?([cp_2, fp_2], pps_1), forms_pps?([cp_2, fp_2], pps_2)}) do
        {true, false} ->
          assert true

        {false, true} ->
          assert true

        incorrect ->
          IO.inspect(incorrect)
          assert false
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

  # describe "pps = 2, popps = 0, wh > 1 " do
  # end

  # answers the question: `does the given list of pools form a pps?`
  defp forms_pps?(list_of_pools, pps) do
    list_of_pools_id = list_of_pools |> Enum.map(& &1.id) |> Enum.sort()
    pps_pool_id = pps.pools |> Enum.map(& &1.id) |> Enum.sort()

    list_of_pools_id == pps_pool_id
  end
end
