
defmodule EncoderHelper do
  def encode_and_store(data, filename) do
    # encoded_data = Jason.encode!(data, pretty: true, encoder: &encode_recursive/1)
    encoded_data =
      data
      |> encode_recursive()
      |> Jason.encode!(pretty: true)

    File.write!(filename, encoded_data)
    # return the original data
    data
  end

  defp encode_recursive(data) do
    case data do
      %{__struct__: struct_name} = struct ->
        struct
        |> Map.from_struct()
        |> Map.new(fn {k, v} -> {k, encode_recursive(v)} end)
        |> Map.merge(%{struct: struct_name})

      list when is_list(list) ->
        Enum.map(list, &encode_recursive/1)

      map when is_map(map) ->
        Map.new(map, fn {k, v} -> {k, encode_recursive(v)} end)

      other -> other
    end
  end

  defimpl Jason.Encoder, for: Tuple do
    def encode(data, opts) when is_tuple(data) do
      Jason.Encode.list(Tuple.to_list(data), opts)
    end
  end

end
