defmodule Fluid.WorldTest do
  use Fluid.DataCase, async: false

  alias Fluid.Model.World
  alias Fluid.Model.Warehouse
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank

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

    # test "At the beginning of every scenario, all of the water is in pools" do

    # end

    # test "conservation of water property - it cannot be created or destroyed in a world" do
    # add it as a change .. do block with after_transaction to validate conservation property.
    # end

    # test "At the end of every scenario, all of the water is in SUCTs and, if there are any CTs in the
    # World, SCTs" do
    # end
  end

  describe "WareHouse Struct Validations" do
    # test "Every Warehouse needs to have a name" do
    #   {:error, error_val} = Warehouse.create()

    #   assert %{
    #            errors: [
    #              %Ash.Error.Changes.Required{
    #                field: :name,
    #                type: :attribute
    #              }
    #            ]
    #          } =
    #            error_val
    # end

    test "warehouse(WH) one and only one UCT" do
      count = Warehouse.count_uncapped_tanks()
      assert count = 1
    end

    test "warehouse (WH) at least one only one pool" do
      count = Warehouse.count_pools()
      assert count >= 1
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

  describe "Connection Struct Validations" do
    test "Defaults for any Connection " do
      assert false
    end
  end

  # describe "Tank Connection Validations" do
  #   test "UCT: Every UCT is linked either to one or more SUCTs and/or to one or more UCPs" do

  #     tank = Tank.new()
  #     assert %{type: :regular_ct} = tank
  #   end
  # end
end
