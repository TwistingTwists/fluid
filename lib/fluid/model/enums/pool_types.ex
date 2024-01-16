defmodule Fluid.PoolCapacityTypes do
  use Ash.Type.Enum, values: [:uncapped, :capped, :fixed]
end
