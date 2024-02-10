defmodule Fluid.Model.Circularity do
  @moduledoc """
  Only related to wh details for circularity
  """
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :inbound_connections, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]]
    attribute :outbound_connections, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]]

    # attribute :inbound_connections,  {:array, Tag}, default: []
    # attribute :outbound_connections,  {:array, Tag}, default: []
    attribute :is_feeder_node, :boolean, default: nil
    attribute :is_unconnected_node, :boolean, default: nil
  end
end
