defmodule Fluid.WorldTest do
  use Fluid.DataCase, async: false

  # setup

  describe "World Struct Validations" do
    test "world has at least one standalone uncapped tank (SUCT)" do
      count = World.count_standalone_uncapped_tank()
      assert count >= 1
    end
  end
