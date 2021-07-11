defmodule ImgWizard.Adapters.MogrifyTest do
  use ExUnit.Case, async: true
  doctest ImgWizard.Adapters.Mogrify

  import ImgWizard.Adapters.Mogrify

  alias ImgWizard.OperationError

  setup do
    filename = "logo_copy.png"

    File.copy!(StaticAsset.path("logo.png"), StaticAsset.path(filename))

    on_exit(fn -> filename |> StaticAsset.path() |> File.rm!() end)

    %{file_path: StaticAsset.path(filename)}
  end

  test "resize/2", %{file_path: file_path} do
    assert %{width: 64, height: 64} = get_dimensions(file_path)
    assert {:ok, _} = resize(file_path, width: 30)
    assert %{width: 30, height: 30} = get_dimensions(file_path)

    assert(
      {:error,
       %OperationError{
         message:
           "mogrify: unable to open image `does_not_exist.png': No such file or directory" <>
             _
       }} = resize("does_not_exist.png")
    )
  end

  defp get_dimensions(path) do
    {_, width, height, _} =
      path
      |> File.read!()
      |> ExImageInfo.info()

    %{width: width, height: height}
  end
end
