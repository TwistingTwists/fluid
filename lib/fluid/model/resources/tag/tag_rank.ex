
defmodule Fluid.Model.Tag.TagRank do
  use Ash.Resource

  attributes do
    uuid_primary_key :id

    attribute :primary, :integer, default: 1
    attribute :secondary, :integer, default: 1
  end
end
