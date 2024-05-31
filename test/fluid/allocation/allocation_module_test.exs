defmodule Fluid.Allocation.AllocationModuleTest do
  use Fluid.DataCase, async: true

  alias Fluid.Test.Factory
  alias Fluid.Model

  describe "unit tests for allocations" do
    setup do
      warehouses = Factory.setup_warehouses_for_allocation(:pool_ct_connections)

      [warehouses: warehouses]
    end

    test "update tag_id in allocations", %{warehouses: _warehouses} do
      tags = Model.Tag.read_all!()

      tag = hd(tags)
      tag_id = tag.id

      # can update tag_id in allocations - set attribute_writable? to true
      assert %{tag_id: ^tag_id} = Model.Allocation.create!(%{volume: "45", tag_id: tag.id})
    end

    test "update pool / tank names", %{warehouses: whs} do
      wh = hd(whs)

      [tank | _r] = wh.tanks
      [pool | _r] = wh.pools

      assert %{total_capacity: 500000, name: "from tests"} = Model.Tank.update!(tank, %{total_capacity: 500000, name: "from tests"})
      assert %{total_capacity: 500000, name: "from tests"} = Model.Pool.update!(pool, %{total_capacity: 500000, name: "from tests"})
      assert %{total_capacity: 500000, name: "from tests"} = Model.Pool.read_by_id!(pool.id)
      assert %{total_capacity: 500000, name: "from tests"} = Model.Tank.read_by_id!(tank.id)
    end
  end
end
