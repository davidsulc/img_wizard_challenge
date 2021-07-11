defmodule ImgWizardApi.Endpoint do
  use Plug.Router

  alias ImgWizard.MetaInfo
  alias ImgWizard.UnhandledFileTypeError
  alias ImgWizardApi.{BadRequest, NoImageUploaded}

  plug(:match)
  plug(Plug.Parsers, parsers: [:multipart])
  plug(:dispatch)

  put "/info" do
    with {:ok, path} <- image_path(conn),
         {:ok, %MetaInfo{} = info} <- metadata_extractor(conn).(path) do
      send_resp(conn, 200, info |> Map.from_struct() |> Jason.encode!())
    else
      {:error, error} -> send_error(conn, error)
    end
  end

  put "/resize" do
    with {:ok, path} <- image_path(conn),
         :ok <- validate_image_content_type(conn),
         {:ok, dimensions} <- requested_dimensions(conn),
         {:ok, %{width: width, height: height}} <- parse_dimensions(dimensions),
         {:ok, _} <-
           resizer(conn).(
             path,
             ImgWizard.Adapters.Mogrify,
             width: width,
             height: height
           ) do
      send_file(conn, 200, path)
    else
      {:error, error} -> send_error(conn, error)
    end
  end

  match _ do
    send_resp(conn, 404, "Not implemented")
  end

  defp send_error(conn, %type{} = error) do
    result =
      error
      |> Map.from_struct()
      |> Map.delete(:__exception__)
      |> Map.put(:error, format_error_name(type))
      |> Jason.encode!()

    send_resp(conn, status(type), result)
  end

  defp metadata_extractor(conn) do
    case conn.assigns[:metadata_extractor] do
      nil -> &ImgWizard.metadata/1
      extractor -> extractor
    end
  end

  defp resizer(conn) do
    case conn.assigns[:resizer] do
      nil -> &ImgWizard.resize/3
      extractor -> extractor
    end
  end

  defp image_path(%Plug.Conn{} = conn) do
    case uploaded_image(conn) do
      {:ok, %{path: path}} -> {:ok, path}
      {:error, _} = error -> error
    end
  end

  defp uploaded_image(%Plug.Conn{body_params: %{"image" => image}}), do: {:ok, image}
  defp uploaded_image(_), do: {:error, NoImageUploaded.exception()}

  # although the content_type can't be trusted (https://hexdocs.pm/plug/Plug.Upload.html#module-security),
  # this validation is good enough: it will return a meaningful error to clients, while requests made in
  # bad faith with a tampered content_type will simply fail later with an OperationError
  defp validate_image_content_type(%Plug.Conn{} = conn) do
    with {:ok, %{content_type: content_type}} <- uploaded_image(conn),
         :ok <- validate_content_type(content_type) do
      :ok
    else
      {:error, _} = error -> error
    end
  end

  defp validate_content_type(type) do
    case String.starts_with?(type, "image/") do
      true ->
        :ok

      _ ->
        {:error,
         BadRequest.exception(message: "expected content_type to be an image, but got `#{type}`")}
    end
  end

  defp requested_dimensions(%Plug.Conn{} = conn) do
    conn = fetch_query_params(conn)

    case Map.take(conn.query_params, ["height", "width"]) do
      %{"width" => w, "height" => h} ->
        {:ok, %{width: w, height: h}}

      _ ->
        {:error,
         BadRequest.exception(
           message: "both `width` and `height` values must be provided as query strings"
         )}
    end
  end

  defp parse_dimensions(%{width: w, height: h}) do
    with {parsed_width, ""} <- Integer.parse(w),
         {parsed_height, ""} <- Integer.parse(h),
         true <- parsed_width > 0,
         true <- parsed_height > 0 do
      {:ok, %{width: parsed_width, height: parsed_height}}
    else
      _ ->
        {:error,
         BadRequest.exception(message: "`width` and `height` values must be positive integers")}
    end
  end

  defp status(BadRequest), do: 400
  defp status(NoImageUploaded), do: 400
  defp status(UnhandledFileTypeError), do: 422
  defp status(_), do: 500

  defp format_error_name(error_module) when is_atom(error_module) do
    error_module
    |> Atom.to_string()
    |> String.replace(~r/^Elixir\.ImgWizard[^\.]*\./, "")
  end
end
