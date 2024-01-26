defmodule Fluid.ModelTest do
  use Fluid.DataCase, async: true

  alias Fluid.Model.World
  alias Fluid.Model.Warehouse
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank
  alias Fluid.Model.Tag
  alias Fluid.Test.Factory

  setup do
    default_string = "- #{__MODULE__}"
    map_or_kv = [name: "Unique world " <> default_string]

    {:ok, world} = Fluid.Model.create_world(map_or_kv)
    {:ok, warehouse} = Fluid.Model.create_warehouse(name: "warehouse1 " <> default_string)

    # one tank of each type - sorted by id of their creation
    tanks = Factory.tanks()

    [world: world, warehouse: warehouse, tanks: tanks]

    # tanks: tanks, pools: pools]
  end

  describe "Warehouse:Name" do
    @tag tested: true
    # @tag :running
    test "create: warehouse cannot have duplicate name", %{
      world: setup_world,
      warehouse: warehouse
    } do
      assert {:error, error} =
               Fluid.Model.create_warehouse(name: warehouse.name)

      assert %Ash.Error.Unknown{
               errors: [
                 %Ash.Error.Unknown.UnknownError{
                   error: error_string
                 }
               ]
             } = error

      # asserts that uniqueness is obtained by postgres unique_constraint
      assert String.contains?(error_string, "index_for_name_unique_entries")
      assert String.contains?(error_string, "(unique_constraint)")
    end
  end

  describe "warehouse(WH) has one and only one UCT" do
    # @tag tested: true
    @tag :running
    test "WH:create: default UCT is created if not provided",
         %{
           world: _setup_world,
           warehouse: warehouse
         } do
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

    # @tag tested: true
    @tag :running
    test "WH:create: if no UCT is given in tank list while creating a warehouse, default UCT is added to WH ",
         %{
           world: _setup_world,
           warehouse: warehouse,
           tanks: tanks
         } do
      # assert that tanks list has at least one UCT
      assert Enum.any?(tanks, fn
               %Tank{
                 location_type: :standalone,
                 capacity_type: :uncapped
               } ->
                 true

               _ ->
                 false
             end)

      assert {:ok, warehouse} =
               Fluid.Model.create_warehouse(name: "Other unique name", tanks: tanks)
               |> dbg()

      tank_ids =
        tanks
        |> Enum.map(& &1.id)
        |> dbg()

      wh_tank_ids =
        warehouse.tanks
        |> Enum.sort_by(& &1.id, :asc)
        |> Enum.map(& &1.id)
        |> dbg()

      assert tank_ids == wh_tank_ids
    end

    # read all worlds
    # Fluid.Model.read(World)

    # create a world
    # Fluid.Model.create_world(map_or_kv)

    # Fluid.Model.create_warehouse(map_or_kv)

    # Fluid.Model.create_tank_standalone(world)

    # Fluid.Model.create_tank_in_warehouse(warehouse, map_or_kv)

    # Fluid.Model.create_pool_in_warehouse(warehouse, map_or_kv)

    # Fluid.Model.add_tanks_to_warehouse(warehouse, tank)
    # Fluid.Model.add_pools_to_warehouse(warehouse, pool)

    # Fluid.Model.connect(tank, pool)
  end
end
