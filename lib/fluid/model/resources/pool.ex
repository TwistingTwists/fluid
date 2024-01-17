defmodule Fluid.Model.Pool do
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: true

    attribute :capacity_type, Fluid.PoolCapacityTypes do
      description "fixed, uncapped, or capped pools can exist"
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
    table "pools"
    repo Fluid.Repo
  end
end
