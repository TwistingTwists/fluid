defmodule Fluid.Model.Circularity do
  @moduledoc """
  Only related to wh details for circularity
  """
  use Ash.Resource
  # , data_layer: :embedded

  attributes do
    uuid_primary_key(:id)
    attribute(:wh_id, :string)
    attribute(:name, :string)
    # warehouse
    attribute(:wh, :map)
    attribute(:inbound_connections, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]])
    attribute(:outbound_connections, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]])

    attribute(:is_feeder_node, :boolean, default: nil)
    attribute(:is_unconnected_node, :boolean, default: nil)
    attribute(:determinate_classes, {:array, :string}, default: [])
    attribute(:indeterminate_classes, {:array, :string}, default: [])
  end

  actions do
    defaults([:create])
  end

  code_interface do
    define_for(Fluid.Model.Api)

    define(:create)
  end
end
