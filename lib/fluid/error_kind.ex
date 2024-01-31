defprotocol Fluid.ErrorKind do
  # @fallback_to_any true

  def message(given_error)
end

# defimpl Fluid.ErrorKind, for: Any do
#   def message(given_error) do
#     keys =
#       given_error
#       |> Map.keys()
#       |> Enum.filter(&(&1 != :__struct__))

#     Map.take(given_error, keys)
#   end
# end
