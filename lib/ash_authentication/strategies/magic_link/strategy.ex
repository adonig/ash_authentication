defimpl AshAuthentication.Strategy, for: AshAuthentication.Strategy.MagicLink do
  @moduledoc false
  alias Ash.Resource
  alias AshAuthentication.{Info, Strategy, Strategy.MagicLink}
  alias Plug.Conn

  @doc false
  @spec name(MagicLink.t()) :: atom
  def name(strategy), do: strategy.name

  @doc false
  @spec phases(MagicLink.t()) :: [Strategy.phase()]
  def phases(_strategy), do: [:request, :accept, :sign_in]

  @doc false
  @spec actions(MagicLink.t()) :: [Strategy.action()]
  def actions(_strategy), do: [:request, :accept, :sign_in]

  @doc false
  @spec method_for_phase(MagicLink.t(), atom) :: Strategy.http_method()
  def method_for_phase(_strategy, :request), do: :post
  def method_for_phase(strategy, :sign_in) when strategy.require_interaction?, do: :post
  def method_for_phase(_strategy, _), do: :get

  @doc false
  @spec routes(MagicLink.t()) :: [Strategy.route()]
  def routes(strategy) do
    subject_name = Info.authentication_subject_name!(strategy.resource)

    routes = [
      {"/#{subject_name}/#{strategy.name}/request", :request},
      {"/#{subject_name}/#{strategy.name}", :sign_in}
    ]

    if strategy.require_interaction? do
      [{"/#{subject_name}/#{strategy.name}", :accept} | routes]
    else
      routes
    end
  end

  @doc false
  @spec plug(MagicLink.t(), Strategy.phase(), Conn.t()) :: Conn.t()
  def plug(strategy, :request, conn), do: MagicLink.Plug.request(conn, strategy)
  def plug(strategy, :accept, conn), do: MagicLink.Plug.accept(conn, strategy)
  def plug(strategy, :sign_in, conn), do: MagicLink.Plug.sign_in(conn, strategy)

  @doc false
  @spec action(MagicLink.t(), Strategy.action(), map, keyword) ::
          :ok | {:ok, Resource.record()} | {:error, any}
  def action(strategy, :request, params, options),
    do: MagicLink.Actions.request(strategy, params, options)

  def action(strategy, :sign_in, params, options),
    do: MagicLink.Actions.sign_in(strategy, params, options)

  @doc false
  @spec tokens_required?(MagicLink.t()) :: true
  def tokens_required?(_), do: true
end
