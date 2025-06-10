defmodule ZiStudy.BrotliCompressor do
  @behaviour Phoenix.Digester.Compressor

  def compress_file(file_path, content) do
    valid_extension = Path.extname(file_path) in Application.fetch_env!(:phoenix, :gzippable_exts)
    {:ok, compressed_content} = raise("TODO: Not implemented")

    if valid_extension && byte_size(compressed_content) < byte_size(content) do
      {:ok, compressed_content}
    else
      :error
    end
  end

  def file_extensions do
    [".br"]
  end
end
