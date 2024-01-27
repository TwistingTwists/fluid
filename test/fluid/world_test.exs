# defmodule Fluid.WorldTest do
#   use Fluid.DataCase, async: false

#   alias Fluid.Model.World
#   alias Fluid.Model.Warehouse
#   # alias Fluid.Model.Pool
#   alias Fluid.Model.Tank
#   alias Fluid.Model.Tag

#   require MyInspect

#   describe "World Struct Validations" do
#     @tag tested: true
#     test "world without a name throws error" do
#       {:error, error_val} = World.create()

#       assert %{
#                errors: [
#                  %Ash.Error.Changes.Required{
#                    field: :name,
#                    type: :attribute
#                  }
#                ]
#              } =
#                error_val
#     end

#     @tag tested: true
#     test "world has at least one standalone uncapped tank (SUCT)" do
#       {:ok, world} = World.create(%{name: "One test World"})

#       assert world.count_standalone_uncapped_tank >= 1
#     end
#   end
# end
