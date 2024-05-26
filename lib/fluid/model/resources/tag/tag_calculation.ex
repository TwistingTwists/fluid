defmodule Fluid.Model.Tag.TagCalculation do
  @moduledoc """
  If user_defined_tag is not nil, that value is used directly, otherwise, default value is assigned.
  """

  use Ash.Calculation

  require Logger
  alias __MODULE__.Parser

  @impl Ash.Calculation
  def calculate(tags, _opts, _resolution) do
    {:ok,
     Enum.map(tags, fn tag ->
       Parser.parse(tag.user_defined_tag)
     end)}
  end

  defmodule Parser do
    @moduledoc """
    This module provides a function to parse a string into a tuple.

    The expected input format is either a string with two integers separated by the character "T",
    or an empty string. If the input is an empty string, the function returns the tuple `{1, 1}`.
    Otherwise, it parses the string and returns a tuple with the two integers.

    """

    @doc """
     Parses the given string into a tuple.

    ## Examples

        iex> Fluid.Model.Tag.TagCalculation.Parser.parse("1T1")
        {1, 1}

        iex> Fluid.Model.Tag.TagCalculation.Parser.parse("1T4")
        {1, 4}

        iex> Fluid.Model.Tag.TagCalculation.Parser.parse("3T")
        {3, 1}

        iex> Fluid.Model.Tag.TagCalculation.Parser.parse("")
        {1, 1}

        iex> Fluid.Model.Tag.TagCalculation.Parser.parse(nil)
        {1, 1}
    """
    def parse(val) when val in ["", nil] do
      {1, 1}
    end

    def parse(input) do
      [head | tail] = String.split(input, "T", parts: 2, trim: true)
      {String.to_integer(head), parse_tail(tail)}
    end

    defp parse_tail([]), do: 1
    defp parse_tail([tail]), do: String.to_integer(tail)
  end
end
