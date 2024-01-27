# defmodule Fluid.TankTest do
#   use Fluid.DataCase, async: false

#   alias Fluid.Model.World
#   alias Fluid.Model.Warehouse
#   alias Fluid.Model.Pool
#   alias Fluid.Model.Tank
#   alias Fluid.Model.Tag

#   describe "Tank Struct Validations" do
#     @tag tested: true
#     test "Tank : can create a standalone uncapped tank" do
#       # A CT that receives Untagged Volume. The default setting is for every CT to be a Regular CT.

#       {:ok, tank} =
#         Tank.create(%{
#           location_type: :standalone,
#           capacity_type: :uncapped
#         })

#       assert %{
#                location_type: :standalone,
#                capacity_type: :uncapped
#              } = tank
#     end
#   end
# end
