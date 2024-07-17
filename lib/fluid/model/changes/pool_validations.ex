defmodule Fluid.Model.Changes.PoolValidations do
  use Ash.Resource.Change

  alias Fluid.Model

  import Helpers.ColorIO

  def change(changeset, opts, _context) do
    case changeset.attributes do
      # fixed pools must have volume
      %{
        entity_type: :fixed,
        location_type: :in_wh,
        volume: volume
      }
      when not is_nil(volume) and volume > 0.0 ->
        changeset

      # capped pools must have capacity
      %{
        entity_type: :capped,
        location_type: :in_wh,
        total_capacity: total_capacity
      }
      when not is_nil(total_capacity) ->
        changeset

      # uncapped pools must have neither volume nor capacity
      %{
        entity_type: :uncapped,
        location_type: :in_wh
      } ->
        changeset

      %{
        location_type: :standalone,
        entity_type: :uncapped,
      } ->
        changeset

      _ ->
        Ash.Changeset.add_error(
          changeset,
          [field: :total_capacity, message: "Capped pool must have a total_capacity" ,
          field: :volume,
          message: "Fixed pool must have a volume"]
        )
    end
  end
end
