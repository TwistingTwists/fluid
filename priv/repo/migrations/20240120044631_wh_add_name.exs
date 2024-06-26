defmodule Fluid.Repo.Migrations.WhAddName do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:warehouses) do
      add :name, :text, null: false
    end

    # create unique_index
    create(
      unique_index(
        :warehouses,
        ~w(name)a,
        name: :index_for_name_unique_entries
      )
    )
  end

  def down do
    alter table(:warehouses) do
      remove :name
    end
  end
end
