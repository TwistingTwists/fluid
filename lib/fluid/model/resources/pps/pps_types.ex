defmodule Fluid.Model.PPS.PPSTypes do
  # other utilities

  use Ash.Type.Enum, values: [:excess_circularity, :det_pps_only, :indet_pps_only]
end
