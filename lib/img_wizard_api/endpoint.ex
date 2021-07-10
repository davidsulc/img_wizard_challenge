defmodule ImgWizardApi.Endpoint do
  use Plug.Router

  alias ImgWizard.MetaInfo

  plug(:match)
  plug(Plug.Parsers, parsers: [:multipart])
  plug(:dispatch)

  put "/info" do
    path = get_image_path(conn)

    case ImgWizard.metadata(path) do
      {:ok, %MetaInfo{} = info} ->
        result =
          info
          |> Map.from_struct()
          |> Jason.encode!()

        send_resp(conn, 200, result)

      {:error, %type{} = error} ->
        result =
          error
          |> Map.from_struct()
          |> Map.delete(:__exception__)
          |> Map.put(:error, format_error_name(type))
          |> Jason.encode!()

        send_resp(conn, status(type), result)
    end
  end

  match _ do
    send_resp(conn, 404, "Not implemented")
  end

  defp get_image_path(%Plug.Conn{body_params: %{"image" => %{path: path}}}), do: path

  defp status(ImgWizard.UnhandledFileTypeError), do: 422
  defp status(_), do: 500

  defp format_error_name(error_module) when is_atom(error_module) do
    error_module
    |> Atom.to_string()
    |> String.replace(~r/^Elixir\.ImgWizard\./, "")
  end
end
