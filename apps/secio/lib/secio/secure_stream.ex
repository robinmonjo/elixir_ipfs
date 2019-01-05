defmodule Secio.SecureStream do
  alias __MODULE__
  alias Secio.Handshake.Support

  @stream_type :aes_ctr

  defstruct [
    :hash_alg,
    :hmac_sig_size,
    :local_hmac_key,
    :local_key,
    :local_iv,
    :local_state,
    :remote_hmac_key,
    :remote_key,
    :remote_iv,
    :remote_state
  ]

  def init(hash_alg, local_opts, remote_opts) do
    %SecureStream{
      hash_alg: hash_alg,
      hmac_sig_size: Support.hash_size(hash_alg),
      local_hmac_key: local_opts[:hmac_key],
      local_key: local_opts[:key],
      local_iv: local_opts[:iv],
      local_state: :crypto.stream_init(@stream_type, local_opts[:key], local_opts[:iv]),
      remote_hmac_key: remote_opts[:hmac_key],
      remote_key: remote_opts[:key],
      remote_iv: remote_opts[:iv],
      remote_state: :crypto.stream_init(@stream_type, remote_opts[:key], remote_opts[:iv])
    }
  end

  def cipher(%SecureStream{} = stream, msg) do
    {next_state, cipher_text} = :crypto.stream_encrypt(stream.remote_state, msg)
    mac = :crypto.hmac(stream.hash_alg, stream.remote_hmac_key, cipher_text)
    {%{stream | remote_state: next_state}, cipher_text <> mac}
  end

  def uncipher(%SecureStream{} = stream, msg) do
    msg_size = byte_size(msg) - stream.hmac_sig_size
    <<data::bytes-size(msg_size), hmac_sig::binary>> = msg

    mac = :crypto.hmac(stream.hash_alg, stream.local_hmac_key, data)

    if mac == hmac_sig do
      {next_state, plain_text} = :crypto.stream_decrypt(stream.local_state, data)
      {:ok, %{stream | local_state: next_state}, plain_text}
    else
      {:error, :hmac_signature_mismatch}
    end
  end
end
