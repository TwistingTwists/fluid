defmodule Fluid.Pps.PoolOverlapMapTest do
  use ExUnit.Case
  alias Fluid.Model

  test "many input => one set" do
    input = %{1 => [0, 2], 2 => [0, 1], 4 => [1], 6 => [2]}
    expected_output = %{1 => [0, 1, 2], 2 => [0, 1, 2], 4 => [0, 1, 2], 6 => [0, 1, 2]}
    assert Model.merge_pool_overlap(input) == expected_output
  end

  test "no overlap => as it is" do
    input = %{1 => [0], 2 => [1], 3 => [2]}
    expected_output = %{1 => [0], 2 => [1], 3 => [2]}
    assert Model.merge_pool_overlap(input) == expected_output
  end

  test "single set => as it is " do
    input = %{1 => [0, 1, 2]}
    expected_output = %{1 => [0, 1, 2]}
    assert Model.merge_pool_overlap(input) == expected_output
  end

  test "many input => multiple sets" do
    input = %{"1" => [0, 1], "2" => [1, 2], "3" => [3], "4" => [3, 4]}

    expected_output = %{"1" => [0, 1, 2], "2" => [0, 1, 2], "3" => [3, 4], "4" => [3, 4]}
    assert Model.merge_pool_overlap(input) == expected_output
  end

  test "many input => multiple sets 2" do
    # contains three level hops to ensure that multiple hops are captured
    # so this is a unique case
    input = %{"1" => [0, 1], "2" => [1, 3], "3" => [2, 4], "4" => [2, 3], "5" => [5]}

    expected_output = %{
      "1" => [0, 1, 2, 3, 4],
      "2" => [0, 1, 2, 3, 4],
      "3" => [0, 1, 2, 3, 4],
      "4" => [0, 1, 2, 3, 4],
      "5" => [5]
    }

    assert Model.merge_pool_overlap(input) == expected_output
  end

  test "empty input" do
    input = %{}
    expected_output = %{}
    assert Model.merge_pool_overlap(input) == expected_output
  end
end
