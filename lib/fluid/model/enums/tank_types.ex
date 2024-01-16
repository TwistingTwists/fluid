defmodule Fluid.TankCapacityTypes do
  use Ash.Type.Enum, values: [:uncapped, :capped]
end

defmodule Fluid.TankRegularityTypes do
  use Ash.Type.Enum, values: [:regular, :non_regular]
end

defmodule Fluid.TankLocationTypes do
  use Ash.Type.Enum, values: [:standlone, :in_wh]
end
