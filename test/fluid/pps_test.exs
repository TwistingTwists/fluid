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

  describe "PPS - all pools form PPS " do
    # Here are the outcomes expected form the tests for PPS module
    # %Model.PPS{type: :det_indet_both} => invalid! => list_WH
    # %Model.PPS{type: :det_only}] = Map.values(pps_map) => [input: list_pps] PPS_Eval_Module =>  [input: list_wh_det] WH_Order_Module (A)
    # %Model.PPS{type: :indet_only} => [input: list_pps] PPS_Eval_Module =>  [input: list_wh_indet] WH_Order_Module (B, C)

    # %{
    #   :mix => [wh: list_wh],
    #   :det_only => [pps: pps_wh, wh: list_wh_det],
    #   :indet_only => [pps: pps_wh, wh: list_wh_indet]
    # }

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
      warehouses = Factory.setup_warehouses_for_circularity()

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
      |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")

      ###### update warehouses list!  ######
      updated_warehouses = [warehouse_1 | rest_wh]

      %{circularity_analysis: Model.circularity_analysis(warehouses), warehouses: updated_warehouses}
    end

    test "I -  all pools form PPS - WH Det ", %{
      warehouses: warehouses,
      circularity_analysis: %{indeterminate: indeterminate, determinate: determinate}
    } do
      # %{"pps_uuid" => %Model.PPS{}}
      pps_map =
        Model.pps_analysis(warehouses)
        # in this case, warehouse - 01 is determinate. so, all PPS are part of determinate WH
        |> IO.inspect(
          label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}",
          syntax_colors: [number: :magenta, atom: :cyan, string: :green, boolean: :magenta, nil: :red]
        )

      assert [%Model.PPS{type: :det_only}] = Map.values(pps_map)
      assert false
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
end
