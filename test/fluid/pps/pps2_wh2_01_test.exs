defmodule Fluid.Pps.Pps2Wh201Test do
  use Fluid.DataCase, async: true

  alias Fluid.Model
  alias Fluid.Test.Factory

  # describe "pps = 1 , wh = 2 , pps_type = det" do
  # end

  # describe "pps = 1 , wh = 2 , pps_type = indet" do
  # end

  describe "pps = 1 , wh = 2 , pps_type = excessive_circularity" do
    setup do
      ###### setup warehouses for circularity  ######
      warehouses = Factory.setup_warehouses_for_circularity(:mix_det_indet)

      [warehouse_1, warehouse_2 | rest_wh] = warehouses
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

      ####################################

      [cp_1, cp_2] = warehouse_1.capped_pools
      [fp_1, fp_2] = warehouse_1.fixed_pools

      [ct_1, ct_2, ct_3, ct_4] = warehouse_1.capped_tanks

      ####################################

      [cp_10, cp_13] = warehouse_2.capped_pools
      [fp_11, fp_12] = warehouse_2.fixed_pools

      [ct_14, ct_15, _ct_16, ct_17] = warehouse_2.capped_tanks

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
      updated_warehouses = [warehouse_1, warehouse_2 | rest_wh]

      %{
        circularity_analysis: Model.circularity_analysis(updated_warehouses),
        warehouses: updated_warehouses,
        pps_calculated: [[cp_1, cp_10, fp_11], [cp_2, fp_2, fp_12, cp_13]],
        pps_analysis_map: Model.pps_analysis(updated_warehouses)
      }
    end
  end
end
