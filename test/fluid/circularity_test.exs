defmodule Fluid.CircularityTest do
  @moduledoc """

  ###########################################################################
  Euler Algorithm

  1. FeederNodes , UnconnectedNodes in world.
    -> determinate
  2. Everything else
    -> indeterminate
  3. Eliminate Feeder nodes and arrows away from them
  4. => some nodes now are unconnected in the world => Eliminate Unconnected nodes
  5. Repeat one.

  """

  use Fluid.DataCase, async: true

  alias Fluid.Model
  import Helpers.ColorIO

  describe "world with circularity - mix determinate and indeterminate - " do
    setup do
      ####### world having circularity #####
      {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1 circularity ")
      {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2 circularity ")
      {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3 circularity ")
      {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4 circularity ")
      {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5 circularity ")
      {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6 circularity ")

      {:ok, warehouse_1} =
        Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_2} =
        Model.add_pools_to_warehouse(warehouse_2, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_3} =
        Model.add_pools_to_warehouse(warehouse_3, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_4} =
        Model.add_pools_to_warehouse(warehouse_4, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_5} =
        Model.add_pools_to_warehouse(warehouse_5, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_6} =
        Model.add_pools_to_warehouse(warehouse_6, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

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

    test "identifies - indeterminate nodes ", %{
      warehouses: warehouses
    } do
      # indeterminate warehouses - 2, 3, 4, 5
      # determinate warehouses - 1, 6

      [
        %{id: _wh_id_1},
        %{id: wh_id_2},
        %{id: wh_id_3},
        %{id: wh_id_4},
        %{id: wh_id_5},
        %{id: _wh_id_6}
      ] = warehouses

      # API
      # total-> all
      %{all: _total_wh, indeterminate: circularity} = Model.circularity_analysis(warehouses)
      # import Helpers.ColorIO
      # circularity |> Map.values() |> Map.new(& {&1.wh_id, %{determinate_class: determinate_class}}) |> purple("in test")
      ###########################################################################
      # assertions related to list of indeterminate nodes
      assert Map.has_key?(circularity, wh_id_2)
      assert Map.has_key?(circularity, wh_id_3)
      assert Map.has_key?(circularity, wh_id_4)
      assert Map.has_key?(circularity, wh_id_5)

      ###########################################################################
      # assertions related to indeterminate classes

      # assert %{indeterminate_class: []} = circularity[wh_id_2]
      # A - can two pools be connected?

      # Class A = every WH that is not of Determinate Class that contains at least one CP and/or UCP that receives water from a WH of Determinate Class
      # 1. If there are no WHs of Determinate Class, classify any random WH as Class A

      # Class B = every WH that is not of Determinate Class that contains at least one CP and/or UCP that receives water from a WH of Class A

      # assert %{indeterminate_class: []} = circularity[wh_id_2]
      # assert %{indeterminate_class: []} = circularity[wh_id_2]
      # assert %{indeterminate_class: []} = circularity[wh_id_2]

      ###########################################################################
      # assertions related to determinate classes

      # 1. Can connection be bidreictional ?
      #   * Pool -> Tank:
      #       # WITHIN WAREHOUSE
      #       # FP = all the connections are within the WH
      #       FP(1) ->  CT(1) -> UCT(1) -> UCP(2)
      #       FP(1) ->  CT(1) -> UCT(1) -> ST
      #       CP(1) -> CT(1) -> UCT(1)

      #       FP(1) -> 50% CT(1) + 25% UCT(1) + 25% CP(1)

      #       # Another warehouse
      #       > CT(1) -> CP(2)
      #       > CT(1) -> ST (standalone)
      #       # is the tank connected to standalone or Pool in another warehouse : Gist of Classification

      #       UCT(1) -> UCP(2)
      ###########################################################################

      # Class 0 = every WH that contains no CPs or UCPs
      # i.e. WH with only FP

      # Class 1 = every WH that contains at least one CP and/or UCP, where all of its CPs and UCPs receive water only from one or more WHs of Class 0
      #
      # Class 2 = every WH that contains at least one CP and/or UCP that receives water from one or more WHs of Class 1, where all of its CPs and UCPs receive water only from one or more WHs of Class 1 or below
    end

    test "identifies - determinate nodes ", %{
      warehouses: warehouses
    } do
      # indeterminate warehouses - 2, 3, 4, 5
      # determinate warehouses - 1, 6

      [
        %{id: wh_id_1},
        %{id: _wh_id_2},
        %{id: _wh_id_3},
        %{id: _wh_id_4},
        %{id: _wh_id_5},
        %{id: wh_id_6}
      ] = warehouses

      %{all: _total_wh, indeterminate: circularity} = Model.circularity_analysis(warehouses)
      ###########################################################################
      # assertions related to list of determinate nodes
      refute Map.has_key?(circularity, wh_id_1)
      refute Map.has_key?(circularity, wh_id_6)
    end
  end

  describe "world with circularity - ALL determinate -  " do
    setup do
      ####### world having circularity - ALL determinate nodes #####
      {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1_0 circularity ")
      {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2_0 circularity ")
      {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3_0 circularity ")
      {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4_0 circularity ")
      {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5_0 circularity ")
      # {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_6_0 circularity ")

      {:ok, warehouse_1} =
        Model.add_pools_to_warehouse(warehouse_1, {:params, [%{capacity_type: :fixed, location_type: :in_wh}]})

      {:ok, warehouse_2} =
        Model.add_pools_to_warehouse(warehouse_2, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_3} =
        Model.add_pools_to_warehouse(warehouse_3, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_4} =
        Model.add_pools_to_warehouse(warehouse_4, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      {:ok, warehouse_5} =
        Model.add_pools_to_warehouse(warehouse_5, {:params, [%{capacity_type: :uncapped, location_type: :in_wh}]})

      # {:ok, warehouse_6} =
      #   Model.add_pools_to_warehouse(warehouse_6, {:params, [%{capacity_type: :fixed, location_type: :in_wh}]})

      [uct_1] = warehouse_1.tanks
      [uct_2] = warehouse_2.tanks
      [uct_3] = warehouse_3.tanks
      # [uct_4] = warehouse_4.tanks
      # [uct_5] = warehouse_5.tanks
      # [uct_6] = warehouse_6.tanks

      # [fp_1] = warehouse_1.pools
      [ucp_2] = warehouse_2.pools
      [ucp_3] = warehouse_3.pools
      [ucp_4] = warehouse_4.pools
      [ucp_5] = warehouse_5.pools
      # [ucp_6] = warehouse_6.pools

      # outbound connections from 1
      {:ok, _} = Fluid.Model.connect(uct_1, ucp_2)
      {:ok, _} = Fluid.Model.connect(uct_1, ucp_4)

      # outbound connections from 2
      {:ok, _} = Fluid.Model.connect(uct_2, ucp_3)

      # outbound connections from 3
      {:ok, _} = Fluid.Model.connect(uct_3, ucp_5)

      # NO outbound connections from 4 and 5

      # diagram for above connections
      # ```mermaid
      # graph TD;
      #     WH_1-->WH_2;
      #     WH_1-->WH_4;
      #     WH_2-->WH_3;
      #     WH_4-->WH_5;
      # ```

      [warehouses: [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5]]
      # |> yellow("all warehouses")
    end

    test "identifies - ONLY determinate nodes ", %{warehouses: warehouses} do
      %{all: _total_wh, indeterminate: indeterminate_circularity, determinate: determinate_circularity} =
        Model.circularity_analysis(warehouses)

      [%{id: wh_id_1}, %{id: wh_id_2}, %{id: wh_id_3}, %{id: wh_id_4}, %{id: wh_id_5}] = warehouses

      refute Map.has_key?(indeterminate_circularity, wh_id_1)
      refute Map.has_key?(indeterminate_circularity, wh_id_2)
      refute Map.has_key?(indeterminate_circularity, wh_id_3)
      refute Map.has_key?(indeterminate_circularity, wh_id_4)
      refute Map.has_key?(indeterminate_circularity, wh_id_5)
    end

    test "classify determinate nodes - 1,2,3,4,5", %{warehouses: warehouses} do
      results = Model.circularity_analysis(warehouses)

      %{all: _total_wh, indeterminate: indeterminate_circularity, determinate: determinate_circularity} = results

      # determinate_circularity
      # |> Enum.map(fn {_k, v} -> v.name end)
      # |> yellow("determinate_circularity #{__ENV__.file}:#{__ENV__.line}")

      # indeterminate_circularity
      # |> Enum.map(fn {_k, v} -> v.name end)
      # |> blue("indeterminate_circularity #{__ENV__.file}:#{__ENV__.line}")

      %{indeterminate: indeterminate_wh_map, determinate: determinate_wh_map} =
      Model.classify(results)
      # |> Map.keys()
      # |> purple("classify #{__ENV__.file}:#{__ENV__.line}")

      determinate_wh_map
      |> Enum.map(fn {_k, circularity} -> {circularity.name, circularity.determinate_classes} end)
      |> Enum.into(%{})
      |> purple("indeterminate_wh_map #{__ENV__.file}:#{__ENV__.line}")

      indeterminate_wh_map
      |> Enum.map(fn {_k, circularity} -> {circularity.name, circularity.determinate_classes} end)
      |> Enum.into(%{})
      |> purple("determinate_wh_map #{__ENV__.file}:#{__ENV__.line}")
    end
  end

  # describe "world with circularity - ALL indeterminate -  " do
  #   setup do
  #     ####### world having circularity - ALL determinate nodes #####
  #     {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1_1 circularity ")
  #     {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2_1 circularity ")
  #     {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3_1 circularity ")
  #     {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4_1 circularity ")
  #     {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5_1 circularity ")
  #     # {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_62 circularity ")

  #     [uct_1] = warehouse_1.tanks
  #     [uct_2] = warehouse_2.tanks
  #     [uct_3] = warehouse_3.tanks
  #     [uct_4] = warehouse_4.tanks
  #     [uct_5] = warehouse_5.tanks
  #     # [uct_6] = warehouse_6.tanks

  #     [ucp_1] = warehouse_1.pools
  #     [ucp_2] = warehouse_2.pools
  #     [ucp_3] = warehouse_3.pools
  #     [ucp_4] = warehouse_4.pools
  #     [ucp_5] = warehouse_5.pools
  #     # [ucp_6] = warehouse_6.pools

  #     # outbound connections from 1
  #     {:ok, _} = Fluid.Model.connect(uct_2, ucp_1)

  #     # outbound connections from 2
  #     {:ok, _} = Fluid.Model.connect(uct_3, ucp_2)

  #     # outbound connections from 3
  #     {:ok, _} = Fluid.Model.connect(uct_4, ucp_3)

  #     # outbound connections from 4
  #     {:ok, _} = Fluid.Model.connect(uct_5, ucp_4)

  #     # outbound connections from 5
  #     {:ok, _} = Fluid.Model.connect(uct_1, ucp_5)

  #     # diagram for above connections
  #     # ```mermaid
  #     # graph TD;
  #     #     WH_1-->WH_2;
  #     #     WH_2-->WH_3;
  #     #     WH_3-->WH_4;
  #     #     WH_4-->WH_5;
  #     #     WH_5-->WH_1;
  #     # ```

  #     [warehouses: [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5]]
  #     # |> yellow("all warehouses")
  #   end

  #   test "identifies - ONLY indeterminate nodes ", %{warehouses: warehouses} do
  #     %{all: _total_wh, indeterminate: indeterminate_circularity, determinate: %{}} =
  #       Model.circularity_analysis(warehouses)

  #     [%{id: wh_id_1}, %{id: wh_id_2}, %{id: wh_id_3}, %{id: wh_id_4}, %{id: wh_id_5}] = warehouses

  #     assert Map.has_key?(indeterminate_circularity, wh_id_1)
  #     assert Map.has_key?(indeterminate_circularity, wh_id_2)
  #     assert Map.has_key?(indeterminate_circularity, wh_id_3)
  #     assert Map.has_key?(indeterminate_circularity, wh_id_4)
  #     assert Map.has_key?(indeterminate_circularity, wh_id_5)
  #   end
  # end

  # describe "Sub Classfication - Determinate - " do
  #   setup do
  #     ####### world having circularity - ALL determinate nodes #####
  #     {:ok, warehouse_1} = Fluid.Model.create_warehouse(name: "warehouse_1_4")
  #     {:ok, warehouse_2} = Fluid.Model.create_warehouse(name: "warehouse_2_4")
  #     {:ok, warehouse_3} = Fluid.Model.create_warehouse(name: "warehouse_3_4")
  #     {:ok, warehouse_4} = Fluid.Model.create_warehouse(name: "warehouse_4_4")
  #     {:ok, warehouse_5} = Fluid.Model.create_warehouse(name: "warehouse_5_4")
  #     {:ok, warehouse_6} = Fluid.Model.create_warehouse(name: "warehouse_62 y ")

  #     [uct_1] = warehouse_1.tanks
  #     [uct_2] = warehouse_2.tanks
  #     [uct_3] = warehouse_3.tanks
  #     [uct_4] = warehouse_4.tanks
  #     [uct_5] = warehouse_5.tanks
  #     [uct_6] = warehouse_6.tanks

  #     # UCP -
  #     [ucp_1] = warehouse_1.pools
  #     [ucp_2] = warehouse_2.pools
  #     # [ucp_3] = warehouse_3.pools
  #     [ucp_4] = warehouse_4.pools
  #     # [ucp_5] = warehouse_5.pools
  #     [ucp_6] = warehouse_6.pools

  #     # TODO: assert whether warehouses are integral or not

  #     # AXIOMS
  #     # add fixed pools to warehouses
  #     # fixed pool is fixed in volume.
  #     # capacity = what is it capable of holding - can have variable volume
  #     # a tank has always no (ZERO) volume to being with
  #     # a fixed Pool starts with inital volume and cannot receive anything (no capacity left).
  #     # a capped pool start with ZERO volume and has potential to receive more ( <= capacity)

  #     fp_1 = Model.Pool.create!(%{pool_type: :fixed, location_type: :in_wh})
  #     fp_5 = Model.Pool.create!(%{pool_type: :fixed, location_type: :in_wh})

  #     Model.add_pools_to_warehouse(warehouse_1, fp_1)
  #     # Model.add_pools_to_warehouse(warehouse_1, [%{pool_type: :fixed}, %{pool_type: :capped}, %{pool_type: :uncapped}])
  #     # green("added FP to WH1")

  #     Model.add_pools_to_warehouse(warehouse_5, fp_5)
  #     # green("added FP to WH5")

  #     # add capped tanks
  #     ct_2 =
  #       Model.Tank.create!(%{capacity_type: :capped, location_type: :in_wh})

  #     # |> yellow("ct_2")

  #     Model.add_tanks_to_warehouse(warehouse_2, ct_2)
  #     # |> green("added CT to WH2")

  #     # outbound connections from 1
  #     {:ok, _} = Fluid.Model.connect(uct_2, ucp_1)
  #     # {:ok, _} = Fluid.Model.connect(ct_2, fp_1)
  #     {:ok, _} = Fluid.Model.connect(uct_4, ucp_1)

  #     # outbound connections from 2
  #     {:ok, _} = Fluid.Model.connect(uct_3, ucp_2)

  #     # outbound connections from 4
  #     {:ok, _} = Fluid.Model.connect(uct_5, ucp_4)

  #     # NO outbound connections from 3 and 5

  #     # diagram for above connections
  #     # ```mermaid
  #     # graph TD;
  #     #     WH_1-->WH_2;
  #     #     WH_1-->WH_4;
  #     #     WH_2-->WH_3;
  #     #     WH_4-->WH_5;
  #     # ```

  #     [warehouses: [warehouse_1, warehouse_2, warehouse_3, warehouse_4, warehouse_5]]
  #     # |> yellow("all warehouses")
  #   end

  #   test "determinate nodes - 0,1,2", %{warehouses: warehouses} do
  #     results = Model.circularity_analysis(warehouses)

  #     %{all: _total_wh, indeterminate: indeterminate_circularity, determinate: determinate_circularity} = results

  #     determinate_circularity
  #     |> Enum.map(fn {_k, v} -> v.name end)
  #     |> yellow("determinate_circularity #{__ENV__.file}:#{__ENV__.line}")

  #     indeterminate_circularity
  #     |> Enum.map(fn {_k, v} -> v.name end)
  #     |> blue("indeterminate_circularity #{__ENV__.file}:#{__ENV__.line}")

  #     %{indeterminate: indeterminate_wh_map, determinate: determinate_wh_map} =
  #       Model.classify(results)

  #     determinate_wh_map |> Enum.map(fn {_k, v} -> v.name end) |> yellow("determinate_wh_map #{__ENV__.file}:#{__ENV__.line}")
  #     indeterminate_wh_map |> Enum.map(fn {_k, v} -> v.name end) |> blue("indeterminate_wh_map #{__ENV__.file}:#{__ENV__.line}")

  #     determinate_wh_map
  #     |> Enum.map(fn {_k, v} -> {v.name, v.determinate_classes} end)
  #     |> yellow("classification results")
  #   end

  #   #   #     [%{id: wh_id_1}, %{id: wh_id_2}, %{id: wh_id_3}, %{id: wh_id_4}, %{id: wh_id_5}] = warehouses

  #   #   #     # Model.classify_determinate(warehouses)
  #   #   #   end

  #   #   # test "indeterminate nodes - A, B, C" do
  #   #   # end
  # end
end
