defmodule Fluid.Model.Tank do
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: true

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

  relationships do
    # toask cannot belong to both at the same time?
    belongs_to :warehouse, Fluid.Model.Warehouse
    # toask can belong_to world directly - iff pool is standalone?
    belongs_to :world, Fluid.Model.World
  end

  actions do
    defaults [:update]

    read :read_all do
      primary? true
    end

    read :read_by_id do
      get_by [:id]
    end

    create :create do
      primary? true
      change load([:world, :warehouse])
    end
  end

  code_interface do
    define_for Fluid.Model.Api

    define :create

    define :read_all
    define :read_by_id, args: [:id]

    define :update
  end

  postgres do
    table "tanks"
    repo Fluid.Repo
  end
end
