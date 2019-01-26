defmodule Secio.Handshake do
  alias Secio.Handshake.{Exchange, Key, Propose, Support}
  alias Secio.SecureStream

  def start(socket) do
    with {:ok, propose_state} <- Propose.start(socket),
         {:ok, exchange_state} <- Exchange.start(socket, propose_state),
         keys <- Key.compute(exchange_state),
         stream <- secure_stream(exchange_state, keys),
         {:ok, ciphered_nonce_in} <- :gen_tcp.recv(socket, 0),
         {:ok, stream, nonce_in} <- SecureStream.uncipher(stream, ciphered_nonce_in),
         true <- nonce_in == propose_state.nonce,
         {stream, ciphered_nonce} <- SecureStream.cipher(stream, propose_state.propose_in.rand),
         :ok <- :gen_tcp.send(socket, ciphered_nonce) do
      {:ok, stream}
    else
      err -> err
    end
  end

  defp secure_stream(%{hash: hash}, %{locale_key: local_key, remote_key: remote_key}) do
    {local_iv, local_key, local_hmac_key} = local_key
    {remote_iv, remote_key, remote_hmac_key} = remote_key

    SecureStream.init(
      Support.hashes(hash),
      [key: local_key, iv: local_iv, hmac_key: local_hmac_key],
      key: remote_key,
      iv: remote_iv,
      hmac_key: remote_hmac_key
    )
  end
end
