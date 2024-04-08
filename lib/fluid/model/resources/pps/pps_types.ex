defmodule Fluid.Model.PPS.PPSTypes do
  # other utilities

  use Ash.Type.Enum, values: [:det_indet_both, :det_only, :indet_only]
end
