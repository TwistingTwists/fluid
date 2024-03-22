defmodule Fluid.PPSTest do
  @moduledoc """

  ###########################################################################
  Pool Priority Set: 
  Two conditions 

  (a) a CT tags more than one pool
  (b) at least one of those tagged pools is tagged by at least one more CT

  Test case diagrams: https://drive.google.com/file/d/16XQDNJEl2TNXePj-UuqhJFhlGr9v9T9g/view?usp=sharing
  """

  use Fluid.DataCase, async: true

  alias Fluid.Model

  describe "PPS - all pools form PPS " do
    test "first case" do
      assert false
    end
  end

  # PPS - some pools form PPS 
  # PPS - no pools form PPS 
  # PPS - multiple PPS within WH
end
