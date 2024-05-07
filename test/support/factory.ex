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

  # @doc """

  # """
  # def setup_warehouses_for_circularity(:det_only) do
  # end
end
