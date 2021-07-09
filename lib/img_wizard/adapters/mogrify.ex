defmodule ImgWizard.Adapters.Mogrify do
  @moduledoc """
  Implements `ImgWizard.Adapters` behaviour using ImageMagick's mogrify.
  """

  alias ImgWizard.Adapter

  @behaviour Adapter

  @doc """
  Resizes an image.

  Returns

  * `{:ok, ""}` if the operation was successful
  * `{:error, reason}` if the operation failed, where `reason` is the string explanation provided by the mogrify command

  Options:

  * `:width`: the desired image width, defaults to 100
  * `:height`: the desired image height, defaults to 100

  Width and height are interpreted as maximum values, with the original aspect ratio preserved.
  """
  @impl true
  @spec resize(String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, String.t()}
  def resize(path, opts \\ []) do
    result =
      System.cmd(
        "mogrify",
        ["-resize", format_dimensions(opts), path],
        stderr_to_stdout: true
      )

    case result do
      {_, 0} -> {:ok, ""}
      {error, _} -> {:error, error}
    end
  end

  @spec format_dimensions(Keyword.t()) :: String.t()
  defp format_dimensions(opts) do
    %{width: w, height: h} = Adapter.get_dimensions(opts)
    "#{w}x#{h}"
  end
end
