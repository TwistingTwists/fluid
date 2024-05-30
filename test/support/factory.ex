defmodule Fluid.Test.Factory do
  alias Fluid.Model
  alias Fluid.Model.Tank
  alias Fluid.Model.Pool

  def tank_params() do
    [
      %{
        location_type: :in_wh,
        capacity_type: :uncapped
      },
      %{
        location_type: :in_wh,
        capacity_type: :capped
      },
      %{
        location_type: :standalone,
        capacity_type: :uncapped
      }
    ]
  end

  def pool_params() do
    [
      %{
        location_type: :in_wh,
        capacity_type: :uncapped
      },
      %{
        location_type: :in_wh,
        capacity_type: :capped
      },
      %{
        location_type: :in_wh,
        capacity_type: :fixed
      },
      %{
        location_type: :standalone,
        capacity_type: :uncapped
      }
    ]
  end

  def tanks() do
    tank_params()
    |> Enum.map(fn tank_params ->
      {:ok, tank} =
        Tank.create(tank_params)

      tank
    end)
    # additionally sort tanks by id to ease out asssertion
    |> Enum.sort_by(& &1.id, :asc)
  end

  def pools() do
    pool_params()
    |> Enum.map(fn pool_params ->
      {:ok, pool} = Pool.create(pool_params)
      pool
    end)
    # additionally sort tanks by id to ease out asssertion
    |> Enum.sort_by(& &1.id, :asc)
  end

  @doc """
  contains a mix of determinate and indeterminate warehouses

  # determinate warehouses - 1, 6
  # indeterminate warehouses - 2, 3, 4, 5
  """
  def setup_warehouses_for_circularity(:mix_det_indet) do
    # to ensure that warehouse names never conflict.
    random_number = Enum.random(1..100)

    {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1 #{__MODULE__} #{random_number}")
    {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2 #{__MODULE__} #{random_number}")
    {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3 #{__MODULE__} #{random_number}")
    {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4 #{__MODULE__} #{random_number}")
    {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5 #{__MODULE__} #{random_number}")
    {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6 #{__MODULE__} #{random_number}")

    {:ok, warehouse_1} =
      Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_2} =
      Model.add_pools_to_warehouse(warehouse_2, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_3} =
      Model.add_pools_to_warehouse(warehouse_3, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_4} =
      Model.add_pools_to_warehouse(warehouse_4, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_5} =
      Model.add_pools_to_warehouse(warehouse_5, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_6} =
      Model.add_pools_to_warehouse(warehouse_6, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    [uct_1] = warehouse_1.tanks
    [uct_2] = warehouse_2.tanks
    [uct_3] = warehouse_3.tanks
    [uct_4] = warehouse_4.tanks
    # [uct_5] = warehouse_5.tanks
    # [uct_6] = warehouse_6.tanks

    # [ucp_1] = warehouse_1.pools
    [ucp_2] = warehouse_2.pools
    [ucp_3] = warehouse_3.pools
    [ucp_4] = warehouse_4.pools
    [ucp_5] = warehouse_5.pools
    [ucp_6] = warehouse_6.pools

    # outbound connections from 1
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_5)
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_2)
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_6)

    # outbound connections from 2
    {:ok, _} = Fluid.Model.connect(uct_2, ucp_3)

    # outbound connections from 3
    {:ok, _} = Fluid.Model.connect(uct_3, ucp_4)

    # outbound connections from 4
    {:ok, _} = Fluid.Model.connect(uct_4, ucp_2)
    {:ok, _} = Fluid.Model.connect(uct_4, ucp_5)

    # NO outbound connections from 5 and 6
    [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5, warehouse_6]
  end

  @doc """
    For allocation,
    - setup circularity
    - setup pps : in this case, pps = 2, wh = 2, pps_type = determinate
  """
  def setup_warehouses_for_allocation(:pool_ct_connections) do
    # to ensure that warehouse names never conflict.
    random_number = Enum.random(101..400)

    {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1 #{__MODULE__} #{random_number}")
    {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2 #{__MODULE__} #{random_number}")
    {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3 #{__MODULE__} #{random_number}")
    {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4 #{__MODULE__} #{random_number}")
    {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5 #{__MODULE__} #{random_number}")
    {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6 #{__MODULE__} #{random_number}")

    {:ok, warehouse_1} =
      Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_2} =
      Model.add_pools_to_warehouse(warehouse_2, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_3} =
      Model.add_pools_to_warehouse(warehouse_3, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_4} =
      Model.add_pools_to_warehouse(warehouse_4, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_5} =
      Model.add_pools_to_warehouse(warehouse_5, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    {:ok, warehouse_6} =
      Model.add_pools_to_warehouse(warehouse_6, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

    [uct_1] = warehouse_1.tanks
    [uct_2] = warehouse_2.tanks
    [uct_3] = warehouse_3.tanks
    [uct_4] = warehouse_4.tanks
    # [uct_5] = warehouse_5.tanks
    # [uct_6] = warehouse_6.tanks

    # [ucp_1] = warehouse_1.pools
    [ucp_2] = warehouse_2.pools
    [ucp_3] = warehouse_3.pools
    [ucp_4] = warehouse_4.pools
    [ucp_5] = warehouse_5.pools
    [ucp_6] = warehouse_6.pools

    # outbound connections from 1
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_5)
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_2)
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_6)

    # outbound connections from 2
    {:ok, _} = Fluid.Model.connect(uct_2, ucp_3)

    # outbound connections from 3
    {:ok, _} = Fluid.Model.connect(uct_3, ucp_4)

    # outbound connections from 4
    {:ok, _} = Fluid.Model.connect(uct_4, ucp_2)
    {:ok, _} = Fluid.Model.connect(uct_4, ucp_5)

    # NO outbound connections from 5 and 6

    # below is taken from pps2_wh2_02_test.exs : setting up the warehouses for
    # world with circularity
    # 2 pps across two warehouses

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

    [cp_1, cp_2 ,fp_1, fp_2]=
    [{cp_1,2000}, {cp_2,500} ,{fp_1,2500}, {fp_2,1000}]
    |> Enum.map(fn ct, volume ->
      Model.Pool.update_volume!(ct, %{volume: volume})
    end)

    [ct_1, ct_2, ct_3, ct_4] = warehouse_1.capped_tanks

    [ct_1, ct_2, ct_3, ct_4] =
      [{ct_1, 1100}, {ct_2, 3000}, {ct_3, 8000}, {ct_4, 1000}]
      |> Enum.map(fn ct, volume ->
        Model.Tank.update_volume!(ct, %{volume: volume})
      end)

    ####################################

    [cp_10, cp_13] = warehouse_6.capped_pools
    [fp_11, fp_12] = warehouse_6.fixed_pools

    [cp_10, cp_13, fp_11, fp_12] =
      [{cp_10, 100}, {cp_13, 2000}, {fp_11, 100}, {fp_12, 2700}]
      |> Enum.map(fn ct, volume ->
        Model.Pool.update_volume!(ct, %{volume: volume})
      end)

    [ct_14, ct_15, _ct_16, ct_17] = warehouse_6.capped_tanks

    [ct_14, ct_15, ct_17] =
      [{ct_14, 600}, {ct_15, 1000}, {ct_17, 1200}]
      |> Enum.map(fn ct, volume ->
        Model.Tank.update_volume!(ct, %{volume: volume})
      end)

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
    [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5, warehouse_6]
  end
end
