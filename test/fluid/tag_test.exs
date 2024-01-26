defmodule Fluid.TagTest do
  use Fluid.DataCase, async: false

  alias Fluid.Model.World
  alias Fluid.Model.Warehouse
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank
  alias Fluid.Model.Tag

  describe "Tag Struct Validations" do
    @tag testing: true
    test "Tag:create - Every UCT (in wh_1) is linked either to one or more SUCTs and/or to one or more UCPs (in wh_2)" do
      # break down this into smaller tests
      # setup - execution (rule / method) - assertion

      # UCT in wh_1 can be linked to UCP in wh_2
      # UCT in wh_1 can be linked to SUCT

      {:ok, pool} =
        Pool.create(%{capacity_type: :uncapped, location_type: :in_wh})
        # Pool.create(warehouse,%{capacity_type: :uncapped, location_type: :in_wh})
        |> MyInspect.print()

      {:ok, suct} =
        Tank.create(%{
          location_type: :standalone,
          capacity_type: :uncapped
        })

      {:ok, warehouse} =
        Warehouse.create(%{name: "test warehouse - tag and tanks and pools"})

      # while warehouse creation, one UCT is created by default with it.
      [uct] =
        warehouse.tanks

      assert {:ok, tag1} =
               Tag.create(uct, pool)

      assert {:ok, tag2} = Tag.create(uct, suct)
      # setup
      # :ok tests and :error tests
    end

    # validate : All Non-Regular CTs must be tagged to one or more pools
  end
end
