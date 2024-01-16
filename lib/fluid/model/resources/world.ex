defmodule Fluid.Model.World do
  @moduledoc """
  World has a unique name.
  World has a SUCT.
  """

  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    # uuid ensures uniqueness of world
    uuid_primary_key :id

    # ensure unique via a unique db constraint
    attribute :name, allow_nil?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  postgres do
    table "worlds"
    repo Fluid.Repo
  end
end
