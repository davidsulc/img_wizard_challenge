defmodule ImgWizardTest do
  use ExUnit.Case, async: true
  doctest ImgWizard

  alias ImgWizard.{FileReadError, UnhandledFileTypeError}

  @metadata %ImgWizard.MetaInfo{
    mimetype: "image/png",
    size: 7636,
    dimensions: %{
      width: 64,
      height: 64
    }
  }

  setup do
    %{
      img: "logo.png",
      non_img: "foobar.txt",
      non_existent: "i_do_not_exist.txt"
    }
  end

  defp asset(context, key) when is_atom(key), do: StaticAsset.path(context[key])

  test "metadata/1", ctx do
    get_metadata = fn key ->
      ctx |> asset(key) |> ImgWizard.metadata()
    end

    assert {:ok, @metadata} = get_metadata.(:img)

    assert {:error, %UnhandledFileTypeError{}} = get_metadata.(:non_img)
    assert {:error, %FileReadError{}} = get_metadata.(:non_existent)
  end

  test "metadata!/1", ctx do
    get_metadata! = fn key ->
      ctx |> asset(key) |> ImgWizard.metadata!()
    end

    assert @metadata = get_metadata!.(:img)

    assert_raise UnhandledFileTypeError, fn -> get_metadata!.(:non_img) end
    assert_raise FileReadError, fn -> get_metadata!.(:non_existent) end
  end
end
