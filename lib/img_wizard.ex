defmodule ImgWizard do
  @moduledoc """
  A simply library to resize image files.
  """

  defmodule MetaInfo do
    @type t() :: %__MODULE__{
            mimetype: String.t(),
            size: byte_count(),
            dimensions: %{
              height: pixel_count(),
              width: pixel_count()
            }
          }

    @type byte_count :: non_neg_integer()

    @type pixel_count :: integer()

    @enforce_keys [:mimetype, :size, :dimensions]
    defstruct [:mimetype, :size, :dimensions]
  end

  alias __MODULE__.{FileReadError, UnhandledFileTypeError}

  @doc "Similar to `metadata/1` but raises an exception if an error occurs."

  @spec metadata!(Path.t()) :: MetaInfo.t()
  def metadata!(file_path) do
    case metadata(file_path) do
      {:ok, metadata} ->
        metadata

      {:error, exception} ->
        raise exception
    end
  end

  @doc """
  Returns `{:ok, metadata}`, where `metadata` is a `t:ImgWizard.MetaInfo/0` containing image information, or `{:error, reason}` if an error occurs.
  """

  @spec metadata(Path.t()) :: {:ok, MetaInfo.t()} | {:error, exception}
        when exception: FileReadError.t() | UnhandledFileTypeError.t()
  def metadata(file_path) do
    with {:ok, %File.Stat{size: size}} <- try_file_operation(file_path, &File.stat/1),
         {:ok, file_contents} <- try_file_operation(file_path, &File.read/1),
         {:ok, {mimetype, width, height, _}} <- get_image_info(file_contents) do
      {:ok,
       %MetaInfo{
         mimetype: mimetype,
         dimensions: %{
           width: width,
           height: height
         },
         size: size
       }}
    end
  end

  @spec try_file_operation(Path.t(), (Path.t() -> {:ok, result} | {:error, term})) ::
          {:ok, result} | {:error, FileReadError.t()}
        when result: term
  defp try_file_operation(path, operation) do
    case operation.(path) do
      {:ok, _} = result ->
        result

      {:error, reason} ->
        {:error, FileReadError.exception(message: "unable to read file #{path}", reason: reason)}
    end
  end

  @spec get_image_info(binary()) ::
          {:ok,
           {mimetype :: String.t(), width :: integer(), height :: integer(),
            variant :: String.t()}}
          | {:error, UnhandledFileTypeError.t()}
  defp get_image_info(file_contents) do
    case ExImageInfo.info(file_contents) do
      nil -> {:error, UnhandledFileTypeError.exception()}
      result -> {:ok, result}
    end
  end

  @doc """
  Resizes the image using the provided adapter and options.
  """

  @spec resize(String.t(), atom, Keyword.t()) :: {:ok, term} | {:error, term}
  def resize(path, adapter, opts \\ [])
      when is_binary(path) and is_atom(adapter) and is_list(opts) do
    adapter.resize(path, opts)
  end
end
