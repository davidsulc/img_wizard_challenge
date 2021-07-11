defmodule ImgWizardApi.BadRequest do
  defexception [:message]

  @opaque t() :: %__MODULE__{}
end

defmodule ImgWizardApi.NoImageUploaded do
  @msg "an image must be provided within the 'image' body param."
  defexception message: @msg

  @opaque t() :: %__MODULE__{}

  def exception(), do: exception(message: @msg)
end
