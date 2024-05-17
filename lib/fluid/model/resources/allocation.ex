defmodule Fluid.Model.Allocation do
  @moduledoc """

  Allocation: The interim step of calculating the amount of water that is assigned from a pool to a
  CT but prior to distributing such water. Allocations may undergo adjustments (e.g.,
  proportional reduction) prior to distribution.

  """
  use Ash.Resource

  attributes do
    uuid_primary_key :id

    attribute :from, :string
    attribute :to, :string
    attribute :volume, :string
  end
end
