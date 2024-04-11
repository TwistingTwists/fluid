defmodule Fluid.Model.PPS do
  @moduledoc """
  PPS in a world (collection of WH)
  """
  use Ash.Resource

  # alias Fluid.Model

  attributes do
    uuid_primary_key(:id)

    attribute(:wh_id, :string)
    attribute(:wh, :map)

    attribute :type, Fluid.Model.PPS.PPSTypes do
      description(
        "PPS is invalid if it has mix of indeterminate and determinate warehouses. which is indicated by type: :det_indet_both"
      )
    end
  end

  actions do
    defaults([:create, :read])
  end

  code_interface do
    define_for(Fluid.Model.Api)

    define(:create)
  end
end
