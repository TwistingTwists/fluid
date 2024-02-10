defmodule Fluid.CircularityTest do
  """
  1. FeederNodes , UnconnectedNodes in world.
    -> determinate
  2. Everything else
    -> indeterminate
  3. Eliminate Feeder nodes and arrows away from them
  4. => some nodes now are unconnected in the world => Eliminate Unconnected nodes
  5. Repeat one.
  """

  """
  Determinate Class

  1. 0 , 1 , 2

  """

  """
  Indeterminate Class

  1. A B C (can have mutliple classes)
  """

  use Fluid.DataCase, async: true

  describe "Circularity" do
    test "world with circularity" do
      asssert(false)
    end

    test "world with circularity ", _ do
      ####### world having circularity #####
      {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1 circularity ")
      {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2 circularity ")
      {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3 circularity ")
      {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4 circularity ")
      {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5 circularity ")
      {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6 circularity ")

      # [uct_1] = warehouse_1.tanks
      [uct_2] = warehouse_2.tanks
      [uct_3] = warehouse_3.tanks
      [uct_4] = warehouse_4.tanks
      [uct_5] = warehouse_5.tanks
      [uct_6] = warehouse_6.tanks

      [ucp_1] = warehouse_1.pools
      [ucp_2] = warehouse_2.pools
      # [ucp_3] = warehouse_3.pools
      [ucp_4] = warehouse_4.pools
      [ucp_5] = warehouse_5.pools
      # [ucp_6] = warehouse_6.pools

      # outbound connections from 1
      {:ok, _} = Fluid.Model.connect(uct_5, ucp_1)
      {:ok, _} = Fluid.Model.connect(uct_2, ucp_1)
      {:ok, _} = Fluid.Model.connect(uct_6, ucp_1)

      # outbound connections from 2
      {:ok, _} = Fluid.Model.connect(uct_3, ucp_2)
      {:ok, _} = Fluid.Model.connect(uct_4, ucp_2)

      # outbound connections from 3
      {:ok, _} = Fluid.Model.connect(uct_5, ucp_4)

      # outbound connections from 5
      {:ok, _} = Fluid.Model.connect(uct_2, ucp_5)

      # NO outbound connections from 3 and 6

      # diagram for above connections
      # ```mermaid
      # graph TD;
      #     WH_1-->WH_2;
      #     WH_1-->WH_5;
      #     WH_1-->WH_6;
      #     WH_2-->WH_3;
      #     WH_2-->WH_4;
      #     WH_4-->WH_5;
      #     WH_5-->WH_2;
      # ```

      warehouses = [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5, warehouse_6]
    end
  end
end
