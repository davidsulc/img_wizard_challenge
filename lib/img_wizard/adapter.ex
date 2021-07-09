defmodule ImgWizard.Adapter do
  @default_dimensions %{width: 100, height: 100}

  @doc """
  Resizes an image.

  Options:

  * `:width`: the desired image width, defaults to 100
  * `:height`: the desired image height, defaults to 100

  How the options are interpreted depends on the specific module implementing this behaviour.
  """
  @callback resize(path :: Path.t(), opts :: Keyword.t()) :: {:ok, term} | {:error, term}

  @doc false
  def get_dimensions(opts) do
    Map.merge(@default_dimensions, opts |> Keyword.take([:width, :height]) |> Enum.into(%{}))
  end
end
