defmodule Fluid.WarehouseTest do
  use Fluid.DataCase, async: false

  alias Fluid.Model
  alias Fluid.Model.Warehouse

  describe "add pool to warehouse" do
    test " - verify database persistence" do
      {:ok, %{id: wh_id} = warehouse_1} =
        Fluid.Model.create_warehouse(name: "warehouse_1 wh ")

      {:ok, pool} =
        Model.Pool.create(%{
          location_type: :in_wh,
          capacity_type: :uncapped
        })

      {:ok, updated_warehouse} = Warehouse.add_pool(warehouse_1, pool)
      %{count_pool: count_pool, count_uncapped_tank: count_uncapped_tank, pools: pools} = updated_warehouse

      assert %{id: ^wh_id} = updated_warehouse

      assert %{count_pool: ^count_pool, count_uncapped_tank: ^count_uncapped_tank, pools: ^pools} = Warehouse.read_by_id!(wh_id)
    end
  end

  #   describe "WareHouse Struct Validations" do
  #     @tag testing: true
  #     test "warehouse(WH) has one and only one UCT - with default tank" do
  #       # create the UCT when creating the warehouse.
  #       {:ok, warehouse} =
  #         Warehouse.create(%{name: "test warehouse - tanks"})

  #       assert warehouse.count_uncapped_tank == 1

  #       # try to add one more tank and it should not succeed
  #       {:ok, tank} =
  #         Tank.create(%{
  #           location_type: :in_wh,
  #           capacity_type: :uncapped
  #         })

  #       assert {:error, error} =
  #                Warehouse.add_tank(warehouse, tank)

  #       assert %{
  #                errors: [
  #                  %Ash.Error.Changes.InvalidAttribute{
  #                    field: :tanks
  #                  }
  #                ]
  #              } = error
  #     end

  #     @tag tested: true
  #     test "warehouse(WH) a unique name" do
  #       # create the UCT when creating the warehouse.
  #       {:ok, warehouse} = Warehouse.create(%{name: "test warehouse"})

  #       assert {:error, error} =
  #                Warehouse.create(%{name: "test warehouse"})
  #     end

  #     @tag tested: true
  #     test "warehouse (WH) has at least one pool" do
  #       {:ok, warehouse} =
  #         Warehouse.create(%{name: "test warehouse - pools"})

  #       assert warehouse.count_pool >= 1
  #       # assert pool struct
  #     end
  #   end
end
