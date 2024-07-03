defmodule Fluid.TagEvaluationTest do

  use Fluid.DataCase, async: true
  alias Fluid.Model


  describe "pool and warehouses" do
    setup do
      Factory.setup_warehouses_for_tag_evaluation()
    end
  end
end
