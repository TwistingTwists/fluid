defmodule Fluid.Model.Changes.AddArgToRelationship do
  @moduledoc """
  A general utility to pass an argument of the current action down to a relationship change
  that is being made.

  Example

  https://github.com/ash-project/ash_hq/blob/844f1ced17d2b1de5ec4b6b035a04951a5fb8c91/lib/ash_hq/docs/resources/dsl/dsl.ex#L61-L67

  ```elixir
    create :create do
      primary? true
      argument :options, {:array, :map}

      argument :extension_id, :uuid do
        allow_nil? false
      end

      change {AshHq.Docs.Changes.AddArgToRelationship, arg: :extension_id, rel: :options}
      change {AshHq.Docs.Changes.AddArgToRelationship, arg: :library_version, rel: :options}
      change manage_relationship(:options, type: :direct_control)
    end

    relationships do

    belongs_to :extension, AshHq.Docs.Extension do
      allow_nil? true
    end

     belongs_to :library_version, AshHq.Docs.LibraryVersion do
      allow_nil? true
    end

    has_many :options, AshHq.Docs.Option
    end
  ```
  """
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    arg = opts[:arg]
    rel = opts[:rel]
    attr = opts[:attr]
    generate = opts[:generate]

    {changeset, arg_value} =
      if attr do
        val = Ash.Changeset.get_attribute(changeset, attr)

        changeset =
          if is_nil(val) && generate do
            Ash.Changeset.force_change_attribute(changeset, attr, generate.())
          else
            changeset
          end

        {changeset, Ash.Changeset.get_attribute(changeset, attr)}
      else
        {changeset, Ash.Changeset.get_argument(changeset, arg)}
      end

    relationship_value = Ash.Changeset.get_argument(changeset, rel)

    new_value =
      cond do
        is_list(relationship_value) ->
          Enum.map(relationship_value, fn val ->
            Map.put(val, arg, arg_value)
          end)

        is_map(relationship_value) ->
          Map.put(relationship_value, arg, arg_value)

        true ->
          relationship_value
      end

    Ash.Changeset.set_argument(changeset, rel, new_value)
  end
end
