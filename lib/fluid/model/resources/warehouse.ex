defmodule Fluid.Model.Warehouse do
  alias Fluid.Model.Tank
  alias __MODULE__
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    # attribute :name, :string, allow_nil?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :world, Fluid.Model.World
    has_many :tanks, Fluid.Model.Tank
    has_many :pools, Fluid.Model.Pool
  end

  calculations do
    calculate :count_uncapped_tank, :integer, {Warehouse.Calculations.UCT, field: :tanks}
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
      argument :tanks, {:array, Tank}, allow_nil?: true
      change load([:tanks, :pools, :world, :count_uncapped_tank])
      change Fluid.Model.Warehouse.Changes.AddDefaultUCT
      change manage_relationship(:tanks, type: :append_and_remove)
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
