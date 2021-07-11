defmodule ImgWizardApi.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ImgWizard.{FileReadError, MetaInfo, UnhandledFileTypeError}
  alias ImgWizardApi.Endpoint

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
  end
end
