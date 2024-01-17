defmodule Fluid.Model.Warehouse do
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :world, Fluid.Model.World
    has_many :tanks, Fluid.Model.Tank
    has_many :pools, Fluid.Model.Pool
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
      change load([:tanks, :pools, :world])
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
    table "warehouses"
    repo Fluid.Repo
  end
end
