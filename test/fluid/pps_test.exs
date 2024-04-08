defmodule Fluid.PPSTest do
  @moduledoc """

  ###########################################################################
  Pool Priority Set: 
  Two conditions 

  (a) a CT tags more than one pool
  (b) at least one of those tagged pools is tagged by at least one more CT

  Test case diagrams: https://drive.google.com/file/d/16XQDNJEl2TNXePj-UuqhJFhlGr9v9T9g/view?usp=sharing
  """

  use Fluid.DataCase, async: true

  alias Fluid.Model

  describe "PPS - all pools form PPS " do
    setup do
      default_string = "- #{__MODULE__}"

      {:ok, warehouse} = Fluid.Model.create_warehouse(name: "warehouse1 " <> default_string)

      {:ok, warehouse} =
        Model.add_pools_to_warehouse(
          warehouse,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh},
             %{capacity_type: :fixed, location_type: :in_wh}
           ]}
        )

      {:ok, warehouse} =
        Model.add_tanks_to_warehouse(
          warehouse,
          {:params,
           [
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh},
             %{capacity_type: :capped, location_type: :in_wh}
           ]}
        )

      [cp1, cp2] = warehouse.capped_pools
      [fp1, fp2] = warehouse.fixed_pools

      [ct1, ct2, ct3, ct4] = warehouse.capped_tanks

      warehouse |> IO.inspect(label: "#{Path.relative_to_cwd(__ENV__.file)}:#{__ENV__.line}")
      # # outbound connections from 1
      # {:ok, _} = Fluid.Model.connect(uct_1, ucp_5)
      # {:ok, _} = Fluid.Model.connect(uct_1, ucp_2)
      # {:ok, _} = Fluid.Model.connect(uct_1, ucp_6)

      [warehouse: warehouse]
    end

    test "I -  all pools form PPS ", %{warehouse: warehouse} do
      assert false
    end
  end

  # PPS - some pools form PPS 
  # PPS - no pools form PPS 
  # PPS - multiple PPS within WH
end
