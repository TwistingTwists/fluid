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

  alias Fluid.Model

  describe "Circularity" do
    setup do
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

      [warehouses: [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5, warehouse_6]]
    end

    test "world with circularity ", %{warehouses: warehouses} do
      # indeterminate warehouses - 2, 3, 4, 5
      # determinate warehouses - 1, 6

      [wh_1, wh_2, wh_3, wh_4, wh_5, wh_6] = warehouses
      wh_1_id = wh_1.id
      # API
      # %Model.Circularity{deterministic: deterministic, indeterministic: indeterministic, errors: errors} = Flow.Model.circularity_analysis(warehouses)
      assert %{^wh_1_id => wh_1_circularity} = Model.circularity_analysis(warehouses)

      assert %Model.Circularity{is_feeder_node: false} = wh_1_circularity
    end

    # test "world without circularity" do
    # end
  end
end
