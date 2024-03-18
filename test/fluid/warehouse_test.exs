defmodule Fluid.WarehouseTest do
  use Fluid.DataCase, async: false

  alias Fluid.Model
  alias Fluid.Model.Tank
  alias Fluid.Model.Warehouse
  alias Fluid.Test.Factory

  describe "Warehouse:Name" do
    setup do
      default_string = "- #{__MODULE__}"
      map_or_kv = [name: "Unique world " <> default_string]

      {:ok, world} = Fluid.Model.create_world(map_or_kv)
      {:ok, warehouse} = Fluid.Model.create_warehouse(name: "warehouse1 " <> default_string)

      # one tank of each type - sorted by id of their creation
      tanks = Factory.tanks()
      pools = Factory.pools()

      [world: world, warehouse: warehouse, tanks: tanks, pools: pools]
    end

    test "create: warehouse cannot have duplicate name",
         %{world: _setup_world, warehouse: warehouse} do
      assert {:error, error} =
               Fluid.Model.create_warehouse(name: warehouse.name)

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
      assert String.contains?(error_string, "index_for_name_unique_entries")
      assert String.contains?(error_string, "(unique_constraint)")
    end
  end

  describe "warehouse(WH) has one and only one UCT - " do
    setup do
      default_string = "- #{__MODULE__}"
      map_or_kv = [name: "Unique world " <> default_string]

      {:ok, world} = Fluid.Model.create_world(map_or_kv)
      {:ok, warehouse} = Fluid.Model.create_warehouse(name: "warehouse1 " <> default_string)

      # add a default pool to the warehouse
      {:ok, warehouse} =
        Model.add_pools_to_warehouse(warehouse, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      # one tank of each type - sorted by id of their creation
      tanks = Factory.tanks()
      pools = Factory.pools()

      [world: world, warehouse: warehouse, tanks: tanks, pools: pools]
    end

    test " WH - create - default UCT is created if not provided",
         %{world: _setup_world, warehouse: warehouse} do
      # only the default uct is present in the default warehouse
      [uct] = warehouse.tanks

      wh_id = warehouse.id

      # also asserts that uct is `:regular`
      assert %{
               warehouse_id: ^wh_id,
               capacity_type: :uncapped,
               regularity_type: :regular,
               location_type: :in_wh
             } = uct

      # check if calculations are working properly
      assert warehouse.count_uncapped_tank == 1
    end

    test "WH:create: if UCT is given in tank list while creating a warehouse. it is added as it is to WH",
         %{world: _setup_world, warehouse: _warehouse, tanks: tanks} do
      # filter out standalone tanks
      tanks =
        Enum.filter(tanks, fn
          %Model.Tank{
            location_type: :in_wh
          } ->
            true

          _ ->
            false
        end)

      # assert that tanks list has at least one UCT
      assert Enum.any?(tanks, fn
               %Model.Tank{location_type: :in_wh, capacity_type: :uncapped} ->
                 true

               _ ->
                 false
             end)

      assert {:ok, warehouse} = Fluid.Model.create_warehouse(name: "Other unique name", tanks: tanks)

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
         %{world: _setup_world, warehouse: _warehouse, tanks: tanks} do
      # filter out standalone tanks
      tanks =
        Enum.filter(tanks, fn
          %Tank{location_type: :in_wh} ->
            true

          _ ->
            false
        end)

      # tanks list doesn't have UCT
      tanks_without_uct =
        Enum.reject(tanks, fn
          %Tank{location_type: :in_wh, capacity_type: :uncapped} ->
            true

          _ ->
            false
        end)

      assert {:ok, warehouse} =
               Fluid.Model.create_warehouse(name: "WH with tank list but no UCT in tank list", tanks: tanks)

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

      # |> purple()

      assert Enum.all?(tanks, fn
               %{
                 location_type: :in_wh,
                 capacity_type: capacity
               }
               when capacity in [:capped, :uncapped] ->
                 true

               _ ->
                 false
             end)

      # sanity check on calculations
      assert warehouse.count_uncapped_tank == 1

      # warehouse2.tanks |> green("warehouse2")
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

      # |> purple()

      # warehouse2.pools |> green("warehouse2")

      assert Enum.all?(pools_result, fn
               %{
                 location_type: :in_wh,
                 capacity_type: capacity
               }
               when capacity in [:fixed, :uncapped] ->
                 true

               _ ->
                 false
             end)

      # sanity check on calculations
      assert warehouse.count_uncapped_tank == 1
      assert warehouse.count_pool == 1
    end

    test "Can connect a given tank in wh_1 to a pool in wh_2", %{
      world: _setup_world,
      warehouse: warehouse_1
    } do
      {:ok, warehouse_2} =
        Fluid.Model.create_warehouse(name: "warehouse_tag_test ")

      {:ok, warehouse_2} =
        Model.add_pools_to_warehouse(warehouse_2, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      [uct] = warehouse_1.tanks
      [ucp] = warehouse_2.pools
      warehouse_1_id = warehouse_1.id
      warehouse_2_id = warehouse_2.id

      assert {:ok, tag} = Fluid.Model.connect(uct, ucp)
      assert %{source: %{"warehouse_id" => ^warehouse_1_id}, destination: %{"warehouse_id" => ^warehouse_2_id}} = tag
    end
  end

  describe "add pool to warehouse" do
    test " - verify database persistence" do
      {:ok, %{id: wh_id} = warehouse_1} =
        Fluid.Model.create_warehouse(name: "warehouse_1 wh persistence")

      {:ok, updated_warehouse} =
        Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      %{count_pool: count_pool, count_uncapped_tank: count_uncapped_tank, pools: pools} = updated_warehouse

      assert %{id: ^wh_id} = updated_warehouse

      assert %{count_pool: ^count_pool, count_uncapped_tank: ^count_uncapped_tank, pools: ^pools} = Warehouse.read_by_id!(wh_id)
    end
  end

  describe "warehouse aggregates and calculations" do
    setup do
      {:ok, warehouse_1} =
        Fluid.Model.create_warehouse(name: "warehouse_1 wh ")

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
      assert warehouse_1.count_ucp_cp == 2
      assert warehouse_1.count_pool == 3
      assert warehouse_1.count_uncapped_tank == 1
    end
  end
end
