defmodule Fluid.Repo.Migrations.AllocationsVolumeFloat do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:allocations) do
      modify :volume, :float
    end
  end

  def down do
    alter table(:allocations) do
      modify :volume, :text
    end
  end
end