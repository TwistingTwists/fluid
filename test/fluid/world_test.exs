defmodule Fluid.WorldTest do
  use Fluid.DataCase, async: false

  alias Fluid.Model.World
  alias Fluid.Model.Warehouse
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank

  require MyInspect

  describe "World Struct Validations" do
    @tag tested: true
    test "Every world needs to have a name" do
      {:error, error_val} = World.create()

      assert %{
               errors: [
                 %Ash.Error.Changes.Required{
                   field: :name,
                   type: :attribute
                 }
               ]
             } =
               error_val
    end

    @tag tested: true
    test "world has at least one standalone uncapped tank (SUCT)" do
      {:ok, world} = World.create(%{name: "One test World"})

      assert world.count_standalone_uncapped_tank >= 1
    end
  end

  describe "WareHouse Struct Validations" do
    @tag tested: true
    test "warehouse(WH) has one and only one UCT - with default tank" do
      # create the UCT when creating the warehouse.
      {:ok, warehouse} =
        Warehouse.create(%{name: "test warehouse - tanks"})

      assert warehouse.count_uncapped_tank == 1

      # try to add one more tank and it should not succeed
      {:ok, tank} =
        Tank.create(%{
          location_type: :in_wh,
          capacity_type: :uncapped
        })

      assert {:error, error} =
               Warehouse.add_tank(warehouse, tank)

      assert %{
               errors: [
                 %Ash.Error.Changes.InvalidAttribute{
                   field: :tanks
                 }
               ]
             } = error
    end

    @tag testing: true
    test "warehouse(WH) a unique name" do
      # create the UCT when creating the warehouse.
      {:ok, warehouse} = Warehouse.create(%{name: "test warehouse"})

      assert {:error, error} =
               Warehouse.create(%{name: "test warehouse"})
    end

    @tag tested: false
    test "warehouse(WH) has one and only one UCT - with given tank" do
      # create the UCT when creating the warehouse.
      {:ok, warehouse} = Warehouse.create(%{name: "test warehouse"})

      assert false
    end

    @tag tested: true
    test "warehouse (WH) has at least one pool" do
      {:ok, warehouse} =
        Warehouse.create(%{name: "test warehouse - pools"})

      assert warehouse.count_pool >= 1
    end

    # test "If any Regular CTs in a WH are not full, then the UCT of that WH must be empty" do
    #
    # end
  end

  describe "Tank Struct Validations" do
    @tag tested: true
    test "Tank : can create a standalone uncapped tank" do
      # A CT that receives Untagged Volume. The default setting is for every CT to be a Regular CT.

      {:ok, tank} =
        Tank.create(%{
          location_type: :standalone,
          capacity_type: :uncapped
        })

      assert %{
               location_type: :standalone,
               capacity_type: :uncapped
             } = tank
    end
  end

  describe "Pool Struct Validations" do
    @tag tested: true
    test "Pool can be created with no default arguments" do
      {:ok, pool} = Pool.create()

      assert %{capacity_type: nil, location_type: nil} = pool
    end
  end

  describe "Connection Struct Validations" do
    @tag tested: false
    test "Defaults for any Connection " do
      assert false
    end
  end
end
