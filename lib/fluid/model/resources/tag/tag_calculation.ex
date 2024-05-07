defmodule Fluid.Model.Tag.TagCalculation do
  @moduledoc """
  If user_defined_tag is not nil, that value is used directly, otherwise, default value is assigned.
  """

  use Ash.Calculation

  require Logger

  @impl Ash.Calculation
  def calculate(tags, _opts, _resolution) do
    {:ok,
     Enum.map(tags, fn tag ->
       if tag.user_defined_tag do
         tag.user_defined_tag
       else
         # default primary rank and secondary rank {1,1}
         "1T1"
       end
     end)}
  end
end
