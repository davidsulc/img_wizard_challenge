defmodule ImgWizard.FileReadError do
  defexception [:reason, message: "unable to open file"]

  @opaque t() :: %__MODULE__{}

  @impl true
  def exception(opts) do
    message = Keyword.fetch!(opts, :message)
    reason = Keyword.fetch!(opts, :reason)

    %__MODULE__{
      message: "#{message} (#{reason})",
      reason: reason
    }
  end
end

defmodule ImgWizard.UnhandledFileTypeError do
  @msg "unhandled file type: make sure this is an image file"
  defexception message: @msg

  @opaque t() :: %__MODULE__{}

  def exception(), do: exception(message: @msg)
end
