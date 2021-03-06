defmodule BlueJet.Service.Option do
  def extract_account(opts, fallback_function \\ fn(_) -> nil end) do
    opts[:account] || fallback_function.(opts)
  end

  def extract_account_id(opts, fallback_function \\ fn(_) -> nil end) do
    opts[:account_id] || extract_account(opts, fallback_function).id
  end

  def extract_pagination(opts) do
    Map.merge(%{ size: 20, number: 1 }, opts[:pagination] || %{})
  end

  def extract_preloads(opts, account \\ nil) do
    account = account || extract_account(opts)
    preloads = opts[:preloads] || %{}
    path = preloads[:path] || []

    opts = preloads[:opts] || %{}
    opts = Map.put(opts, :account, account)

    %{ path: path, opts: opts }
  end
end