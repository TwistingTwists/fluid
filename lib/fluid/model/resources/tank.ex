defmodule Fluid.Model.Tank do
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :name, allow_nil?: true

    attribute :capacity_type, Fluid.TankCapacityTypes do
      description "uncapped, capped"
    end

    attribute :regularity_type, Fluid.TankRegularityTypes do
      description "regular tanks are default"
      default :regular
    end

    attribute :location_type, Fluid.TankLocationTypes do
      description "Whether it is standalone or in warehouse"
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  postgres do
    table "tanks"
    repo Fluid.Repo
  end
end
