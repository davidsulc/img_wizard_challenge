ExUnit.start()

defmodule StaticAsset do
  def path(filename) when is_binary(filename) do
    Path.join([__DIR__, "fixtures", filename])
  end
end
