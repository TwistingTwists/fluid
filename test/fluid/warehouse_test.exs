defmodule Fluid.WarehouseTest do
  use Fluid.DataCase, async: false

  alias Fluid.Model
  alias Fluid.Model.Tank
  alias Fluid.Model.Warehouse
  alias Fluid.Test.Factory

  describe "Warehouse:Name" do
    setup do
      map_or_kv = [name: "Unique world from warehouse_test"]

      {:ok, world} = Fluid.Model.create_world(map_or_kv)
      # world: world in create_warehouse
      {:ok, warehouse} = Fluid.Model.create_warehouse(name: "warehouse_1", world_id: world.id)

      [world: world, warehouse: warehouse]
    end

    test "create: warehouse CANNOT have duplicate name in SAME world",
         %{world: setup_world, warehouse: warehouse} do
      assert {:error, error} =
               Fluid.Model.create_warehouse(name: warehouse.name, world_id: setup_world.id)

      # convert this to warehouse_already_exists
      assert %Fluid.Error.ModelError{
               class: :create_error,
               target: "warehouse",
               error: %{
                 errors: [
                   %{
                     error: error_string
                   }
                 ]
               }
             } =
               error

      # asserts that uniqueness is obtained by postgres unique_constraint
      assert String.contains?(error_string, "warehouses_unique_name_in_world_index")
      assert String.contains?(error_string, "constraint_type: :unique")
    end

    test "create: warehouse CAN have a duplicate name in ANOTHER world",
         %{world: _setup_world, warehouse: warehouse} do
      {:ok, new_world} = Model.create_world(name: "new test world in warehouse_test")

      assert {:ok, _new_wh} =
               Fluid.Model.create_warehouse(name: warehouse.name, world_id: new_world.id)

      # |> green("new warheouse ")
    end
  end

  describe "warehouse(WH) has one and only one UCT - " do
    setup do
      map_or_kv = [name: "Unique world 2 from warehouse_test"]

      {:ok, world} = Fluid.Model.create_world(map_or_kv)
      {:ok, warehouse} = Fluid.Model.create_warehouse(name: "warehouse_1", world_id: world.id)

      # add a default pool to the warehouse
      {:ok, warehouse} =
        Model.add_pools_to_warehouse(warehouse, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      # one tank of each type - sorted by id of their creation
      tanks = Factory.tanks()
      pools = Factory.pools()

      # filter out standalone tanks
      tanks_no_suct =
        Enum.filter(tanks, fn
          %Model.Tank{
            location_type: :in_wh
          } ->
            true

          _ ->
            false
        end)

      [world: world, warehouse: warehouse, tanks: tanks, pools: pools, tanks_no_suct: tanks_no_suct]
    end

    test " WH:create - default UCT is created if not provided",
         %{world: _setup_world, warehouse: warehouse} do
      # only the default uct is present in the default warehouse
      [uct] = Model.get_tanks_from_wh(warehouse)
      # [uct] = warehouse.tanks

      wh_id = warehouse.id

      assert Model.Tank.is_uncapped?(uct)

      # check if calculations are working properly
      assert Model.count_uncapped_tanks_in_wh(warehouse) == 1
      # assert warehouse.count_uncapped_tank == 1
    end

    test "WH:create: if UCT is given in tank list while creating a warehouse. it is added as it is to WH",
         %{world: _setup_world, warehouse: _warehouse, tanks_no_suct: tanks} do
      {:ok, new_test_world} = Fluid.Model.create_world(name: "new test world")

      assert {:ok, warehouse} = Fluid.Model.create_warehouse(name: "Other unique name", world_id: new_test_world.id, tanks: tanks)

      tank_ids =
        tanks
        |> Enum.map(& &1.id)

      wh_tank_ids =
        warehouse.tanks
        |> Enum.sort_by(& &1.id, :asc)
        |> Enum.map(& &1.id)

      assert tank_ids == wh_tank_ids
    end

    test "WH:create: if no UCT is given in tank list while creating a warehouse, default UCT is added to WH ",
         %{world: _setup_world, warehouse: _warehouse, tanks_no_suct: tanks} do
      {:ok, new_test_world} = Fluid.Model.create_world(name: "new test world")

      # tanks list doesn't have UCT
      tanks_without_uct =
        Enum.reject(tanks, fn
          %Tank{location_type: :in_wh, capacity_type: :uncapped} ->
            true

          _ ->
            false
        end)

      assert {:ok, warehouse} =
               Fluid.Model.create_warehouse(
                 name: "WH with tank list but no UCT in tank list",
                 world_id: new_test_world.id,
                 tanks: tanks
               )

      tank_ids =
        tanks_without_uct
        |> Enum.map(& &1.id)

      wh_tank_ids =
        warehouse.tanks
        |> Enum.sort_by(& &1.id, :asc)
        |> Enum.map(& &1.id)

      tanks_in_wh = length(wh_tank_ids)
      assert tanks_in_wh == length(tank_ids) + 1
    end

    test "WH:add_tanks_to_warehouse - add tanks to a given warehouse", %{
      world: _setup_world,
      warehouse: warehouse,
      tanks: tanks
    } do
      # non UCT tank
      [tank] =
        Enum.filter(tanks, fn
          %{
            location_type: :in_wh,
            capacity_type: :capped
          } ->
            true

          _ ->
            false
        end)

      assert {:ok, %{tanks: tanks}} =
               Fluid.Model.add_tanks_to_warehouse(warehouse, tank)


      assert Factory.all_tanks_of_type?(tanks, [:capped, :uncapped])

      # sanity check on calculations
      assert Model.count_uncapped_tanks_in_wh(warehouse) == 1
    end

    test "Can add pools to a given warehouse", %{world: _setup_world, warehouse: warehouse, pools: pools} do
      # fixed pool
      [pool] =
        Enum.filter(pools, fn
          %{
            location_type: :in_wh,
            capacity_type: :fixed
          } ->
            true

          _ ->
            false
        end)

      assert {:ok, %{pools: pools_result} = _warehouse2} =
               Fluid.Model.add_pools_to_warehouse(warehouse, pool)

      assert Factory.all_pools_of_type?(pools_result, [:fixed, :uncapped])

      # sanity check on calculations
      assert Model.count_uncapped_tanks_in_wh(warehouse) == 1

      assert Model.count_pool_in_wh(warehouse) == 1
    end

    test "Can connect a given tank in wh_1 to a pool in wh_2", %{
      world: _setup_world,
      warehouse: warehouse_1
    } do
      {:ok, new_test_world} = Fluid.Model.create_world(name: "new test world")

      {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_tag_test ", world_id: new_test_world.id)

      {:ok, warehouse_2} =
        Model.add_pools_to_warehouse(warehouse_2, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      [uct] = Model.get_tanks_from_wh(warehouse_1)
      [ucp] = Model.get_pools_from_wh(warehouse_2)

      assert {:ok, tag} = Fluid.Model.connect(uct, ucp)
      assert Model.tag_connects?(tag, warehouse_1, warehouse_2)
    end
  end

  describe "add pool to warehouse" do
    test " - verify database persistence" do
      {:ok, new_test_world} = Fluid.Model.create_world(name: "new test world 2")

      {:ok, %{id: wh_id} = warehouse_1} =
        Fluid.Model.create_warehouse(name: "warehouse_tag_test with persistence", world_id: new_test_world.id)

      {:ok, updated_warehouse} =
        Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      count_pool = Model.count_pool_in_wh(updated_warehouse)
      count_uncapped_tank = Model.count_uncapped_tanks_in_wh(updated_warehouse)
      pools = Model.get_pools_from_wh(updated_warehouse)

      assert %{id: ^wh_id} = updated_warehouse

      wh_from_db =  Warehouse.read_by_id!(wh_id)
      pools_returned = Model.get_pools_from_wh(wh_from_db)

      assert count_pool == Model.count_pool_in_wh(wh_from_db)
      assert count_uncapped_tank == Model.count_uncapped_tanks_in_wh(wh_from_db)

      pool_ids_old = pools |> Enum.map(& &1.id) |> Enum.sort()
      poold_ids_returned = pools_returned |> Enum.map(& &1.id) |> Enum.sort()
      assert pool_ids_old == poold_ids_returned
    end
  end

  describe "warehouse aggregates and calculations" do
    setup do
      {:ok, new_test_world} = Fluid.Model.create_world(name: "new test world describe 3")

      {:ok, warehouse_1} =
        Fluid.Model.create_warehouse(name: "warehouse_tag_test with persistence", world_id: new_test_world.id)

      {:ok, warehouse_1} =
        Model.add_pools_to_warehouse(
          warehouse_1,
          {:params,
           [
             %{capacity_type: :fixed, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :uncapped, location_type: :in_wh}
           ]}
        )

      %{warehouse: warehouse_1}
    end

    test "aggregates and calcs", %{warehouse: warehouse_1} do
      assert Model.count_uncapped_tanks_in_wh(warehouse_1) == 1
      assert Model.count_pool_in_wh(warehouse_1) == 3
      assert Model.count_ucp_cp_in_wh(warehouse_1) == 2
    end
  end
end
