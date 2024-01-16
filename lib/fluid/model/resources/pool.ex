defmodule Fluid.Model.Pool do
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :name, allow_nil?: true

    attribute :capacity_type, Fluid.PoolCapacityTypes do
      description "fixed, uncapped, or capped pools can exist"
    end

    attribute :location_type, Fluid.TankLocationTypes do
      description "Whether it is standalone or in warehouse"
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  postgres do
    table "pools"
    repo Fluid.Repo
  end
end
