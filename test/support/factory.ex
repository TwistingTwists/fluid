defmodule Fluid.Test.Factory do
  alias Fluid.Model
  alias Fluid.Model.Tank
  alias Fluid.Model.Pool
  # import Helpers.ColorIO

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
    |> Enum.map(&Tank.create!/1)
    # additionally sort tanks by id to ease out asssertion
    |> Enum.sort_by(& &1.id, :asc)
  end

  def pools() do
    pool_params()
    |> Enum.map(&Pool.create!/1)
    # additionally sort tanks by id to ease out asssertion
    |> Enum.sort_by(& &1.id, :asc)
  end

  @doc """
  contains a mix of determinate and indeterminate warehouses

  # determinate warehouses - 1, 6
  # indeterminate warehouses - 2, 3, 4, 5
  """
  def setup_warehouses_for_circularity(:mix_det_indet) do
    {:ok, world} = Fluid.Model.create_world(name: "Unique world from factories")

    {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1", world_id: world.id)
    {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2", world_id: world.id)
    {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3", world_id: world.id)
    {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4", world_id: world.id)
    {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5", world_id: world.id)
    {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6", world_id: world.id)

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

    [[uct_1], [uct_2], [uct_3], [uct_4]] =
      [warehouse_1, warehouse_2, warehouse_3, warehouse_4]
      |> Enum.map(&Model.wh_get_tanks/1)

    # [uct_1] = warehouse_1.tanks
    # [uct_2] = warehouse_2.tanks
    # [uct_3] = warehouse_3.tanks
    # [uct_4] = warehouse_4.tanks
    # [uct_5] = warehouse_5.tanks
    # [uct_6] = warehouse_6.tanks

    # [ucp_1] = warehouse_1.pools
    [ [ucp_2], [ucp_3], [ucp_4],[ucp_5],[ucp_6]] =
      [ warehouse_2, warehouse_3, warehouse_4,warehouse_5,warehouse_6]
      |> Enum.map(&Model.wh_get_pools/1)

    # [ucp_2] = warehouse_2.pools
    # [ucp_3] = warehouse_3.pools
    # [ucp_4] = warehouse_4.pools
    # [ucp_5] = warehouse_5.pools
    # [ucp_6] = warehouse_6.pools

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
    {:ok, world} = Fluid.Model.create_world(name: "Unique world from factories 2")

    {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1", world_id: world.id)
    {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2", world_id: world.id)
    {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3", world_id: world.id)
    {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4", world_id: world.id)
    {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5", world_id: world.id)
    {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6", world_id: world.id)

    # to_improve: convenience - add_pool_to_warehouse
    # to_discuss: are there uncapped pools? - capped / fixed

    # all tanks start with 0 volume.

    # Do the pools have a default volume? - NO
    # FP - Volume at start HAS TO be defined.
    # Capped - Volume - equal to CT it is connected (tagged) to.
    # at start, CT, CP both have 0 volume
    # when we connect CT with CP then, the volume of CT does not change.
    # capacity of CT and CP MUST be the same. Ensure this when we are connecting the two - CT and CP. (unanswered)

    # at runtime, when volume enters CT -> it flows automatically to CP

    # FP always have a fixed volume. At start.

    # Can we have uncapped pools?  - YES
    # Uncapped - Volume - 0 at start.

    # Can pools live outside the warehouse? - NO
    # MUST fixed pool need to have volume attribute set at start? - YES

    # tanks and pools in warehouse need to have a unique name within a warehouse. - YES

    # {:ok, warehouse_1} =
    # Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})
    # Model.add_pools_to_warehouse(warehouse_1, {:params, [%{name: "", pool_type: :fixed, volume: 67}]})
    # Model.add_pools_to_warehouse(warehouse_1, {:params, [%{pool_type: :capped / :uncapped }]}) # -- NO :volume ATTRIBUTE

    # Model.add_pools_to_warehouse(warehouse_1, {:params, [%{pool_type: :uncapped, volume: 67}]}) -- INVALID

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

    # wh: query tanks by type (API wh.uncapped_tanks)
    # wh: at least one UCT + at least (one of FP / CP) - todo: instead of default uncapped, do capped / fp

    # todo: wh: add a `is_valid` key in warehouse, `reason` - the reason to show in UI

    [[uct_1], [uct_2], [uct_3], [uct_4]] =
      [warehouse_1, warehouse_2, warehouse_3, warehouse_4]
      |> Enum.map(&Model.wh_get_tanks/1)

    [ [ucp_2], [ucp_3], [ucp_4],[ucp_5],[ucp_6]] =
      [ warehouse_2, warehouse_3, warehouse_4,warehouse_5,warehouse_6]
      |> Enum.map(&Model.wh_get_pools/1)

    # Fluid.Model.connect("wh_1" , "ct_1", "wh_2", "cp_1")
    # Frontend
    # "wh_1" , "ct_1", "wh_2", "cp_1" = params from frontend
    # uuids, integer, string, atoms

    # LiveView
    # - params from frontend
    # - handle_event -> params => API.changeset() |> Repo.insert()

    # outbound connections from 1
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_5)
    {:ok, _} = Fluid.Model.connect(uct_1, ucp_2)

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

    # to_improve: make it simpler to use in iex
    # Model.add_tanks_to_warehouse(warehouse)

    ####################################

    # [cp_1, cp_2] = warehouse_1.capped_pools
    # [fp_1, fp_2] = warehouse_1.fixed_pools

    [cp_1, cp_2] = Model.wh_get_capped_pools(warehouse_1)
    [fp_1, fp_2] = Model.wh_get_fixed_pools(warehouse_1)

    [cp_1, cp_2, fp_1, fp_2] =
      [{cp_1, 2000, "cp_1"}, {cp_2, 500, "cp_2"}, {fp_1, 2500, "fp_1"}, {fp_2, 1000, "fp_2"}]
      |> Enum.map(fn {ct, total_capacity, name} ->
        Model.Pool.update!(ct, %{total_capacity: total_capacity, volume: total_capacity, name: name})
        # |> IO.inspect(label: "pool wh1")
      end)

    [ct_1, ct_2, ct_3, ct_4] = warehouse_1.capped_tanks

    [ct_1, ct_2, ct_3, ct_4] =
      [{ct_1, 1100, "ct_1"}, {ct_2, 3000, "ct_2"}, {ct_3, 8000, "ct_3"}, {ct_4, 1000, "ct_4"}]
      |> Enum.map(fn {ct, total_capacity, name} ->
        Model.Tank.update!(ct, %{total_capacity: total_capacity, name: name})
      end)

    ####################################

    [cp_10, cp_13] = warehouse_6.capped_pools
    [fp_11, fp_12] = warehouse_6.fixed_pools

    [cp_10, cp_13, fp_11, fp_12] =
      [{cp_10, 100, "cp_10"}, {cp_13, 2000, "cp_13"}, {fp_11, 100, "fp_11"}, {fp_12, 2700, "fp_12"}]
      |> Enum.map(fn {ct, total_capacity, name} ->
        Model.Pool.update!(ct, %{total_capacity: total_capacity, volume: total_capacity, name: name})
        # |> IO.inspect(label: "pool wh1")
      end)

    [ct_14, ct_15, _ct_16, ct_17] = warehouse_6.capped_tanks

    [ct_14, ct_15, ct_17] =
      [{ct_14, 600, "ct_14"}, {ct_15, 1000, "ct_15"}, {ct_17, 1200, "ct_17"}]
      |> Enum.map(fn {ct, total_capacity, name} ->
        Model.Tank.update!(ct, %{total_capacity: total_capacity, name: name})
      end)

    # [ct_14, ct_15, ct_17]
    # [cp_10, cp_13, fp_11, fp_12]
    #   |> Enum.map(& &1.name) |> orange("ct names ")

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

    # Model.Warehouse.read_by_id!(warehouse_1.id) |> Enum.map(& &1.name) |> orange("wh.pools names")

    # caution: re read all warehouses from db - just to make sure all the latest data is reloaded back in them.
    [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5, warehouse_6]
    |> Enum.map(fn wh -> Model.Warehouse.read_by_id!(wh.id) end)
  end

  ##################
  ##################
  def all_tanks_of_type?(tanks, capacities) when is_list(capacities) do
    do_enum_all(tanks, capacities)
  end

  def all_pools_of_type?(pools, capacities) when is_list(capacities) do
    do_enum_all(pools, capacities)
  end

  def do_enum_all(tank_or_pools, capacities) do
    Enum.all?(tank_or_pools, fn
      %{
        capacity_type: capacity
      } ->
        if capacity in capacities do
          true
        else
          false
        end
    end)
  end
end
