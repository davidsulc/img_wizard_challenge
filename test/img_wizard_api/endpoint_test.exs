defmodule ImgWizardApi.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ImgWizard.{FileReadError, MetaInfo, UnhandledFileTypeError}
  alias ImgWizardApi.Endpoint

  defp test_no_upload(route) do
    assert {400, _headers, body} =
             conn(:put, route)
             |> Endpoint.call([])
             |> sent_resp()

    assert %{
             error: "NoImageUploaded",
             message: "an image must be provided within the 'image' body param."
           } = Jason.decode!(body, keys: :atoms)
  end

  test "PUT /info" do
    call_with_response = fn resp ->
      conn(:put, "/info", %{"image" => %Plug.Upload{}})
      |> assign(:metadata_extractor, fn _ -> resp end)
      |> Endpoint.call([])
      |> sent_resp()
    end

    expected = %{mimetype: "image/png", size: 1234, dimensions: %{width: 12, height: 34}}

    assert {200, _headers, body} = call_with_response.({:ok, struct(MetaInfo, expected)})
    assert ^expected = Jason.decode!(body, keys: :atoms)

    assert {422, _headers, body} = call_with_response.({:error, %UnhandledFileTypeError{}})

    assert %{
             error: "UnhandledFileTypeError",
             message: "unhandled file type: make sure this is an image file"
           } = Jason.decode!(body, keys: :atoms)

    assert {500, _headers, body} = call_with_response.({:error, %FileReadError{}})

    assert %{error: "FileReadError", message: "unable to open file"} =
             Jason.decode!(body, keys: :atoms)

    test_no_upload("/info")
  end

  describe "PUT /resize" do
    setup do
      {:ok, path} = Plug.Upload.random_file("resize_test")

      File.cp!(StaticAsset.path("logo.png"), path)

      %{
        upload: %Plug.Upload{
          path: path,
          filename: "logo.png",
          content_type: "image/png"
        }
      }
    end

    test "requires a file upload" do
      test_no_upload("/resize")
    end

    test "requires width and height parameters as positive integers", %{upload: upload} do
      test_resize_query = &test_resize(&1, upload)

      assert {200, _header, _body} = test_resize_query.("width=12&height=23")

      failures = [
        "",
        "width=12",
        "height=12",
        "width=ab&height=12",
        "width=12&height=cd",
        "width=-2&height=23",
        "width=12&height=-23"
      ]

      for failure <- failures do
        assert {400, _header, _body} = test_resize_query.(failure)
      end
    end

    defp test_resize(query_string, upload, stub \\ true) do
      conn = conn(:put, "/resize?#{query_string}", %{"image" => upload})

      conn =
        case stub do
          false -> conn
          true -> assign(conn, :resizer, fn _, _, _ -> {:ok, nil} end)
        end

      conn
      |> Endpoint.call([])
      |> sent_resp()
    end

    test "requires upload to be an image", %{upload: upload} do
      test_resize_upload = &test_resize("width=12&height=23", &1)

      assert {200, _header, _body} = test_resize_upload.(upload)

      assert {400, _header, _body} = test_resize_upload.(%{upload | content_type: "text/plain"})
    end

    test "resizes the image", %{upload: upload} do
      scenarios = [
        # reduce
        {40, 40},
        {25, 40},
        {40, 25},
        # same as original size
        {64, 64},
        # enlarge
        {90, 90},
        {90, 70},
        {70, 90}
      ]

      for {width, height} <- scenarios do
        assert {200, _header, body} =
                 test_resize("height=#{height}&width=#{width}", upload, false)

        # Fixture image is square and mogrify interprets the provided dimension as a maximum
        # bounding box while preserving the aspect ratio. Therefore, the resized dimensions
        # should be those of the smallest value.

        dim = min(height, width)

        {_mimetype, ^dim, ^dim, _} = ExImageInfo.info(body)
      end
    end

    test "handles non-images provided with image content types", %{upload: upload} do
      {:ok, path} = Plug.Upload.random_file("resize_test")
      File.cp!(StaticAsset.path("foobar.txt"), path)

      assert {500, _header, body} =
               test_resize("height=40&width=40", %{upload | path: path}, false)

      assert %{
               error: "OperationError",
               message: "mogrify: no decode delegate for this image format" <> _
             } = Jason.decode!(body, keys: :atoms)
    end
  end
end
