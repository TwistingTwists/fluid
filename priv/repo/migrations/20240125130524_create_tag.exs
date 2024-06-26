defmodule Fluid.Repo.Migrations.CreateTag do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:tanks) do
      add :tag_id, :uuid
    end

    create table(:tags, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :source, :map, null: false
      add :destination, :map, null: false
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    alter table(:pools) do
      add :tag_id, :uuid
    end
  end

  def down do
    alter table(:pools) do
      remove :tag_id
    end

    drop table(:tags)

    alter table(:tanks) do
      remove :tag_id
    end
  end
end
