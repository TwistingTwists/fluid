defmodule MyInspect do
  defmacro print(opts) do
    %{module: module, function: fun, file: file, line: line} = __CALLER__

    quote do
      IO.inspect("==========#{unquote(module)}:#{inspect(unquote(fun))}==========\n")
      IO.inspect(unquote(opts))
      IO.inspect("==========#{unquote(file)}:#{unquote(line)}==========\n")
      unquote(opts)
    end
  end
end
