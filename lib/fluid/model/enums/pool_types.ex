defmodule Fluid.PoolTypes do
  use Ash.Type.Enum, values: [:capped, :fixed]
  # use Ash.Type.Enum, values: [:uncapped, :capped, :fixed]
end
