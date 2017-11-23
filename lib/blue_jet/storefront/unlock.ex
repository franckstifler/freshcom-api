defmodule BlueJet.Storefront.Unlock do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.AccessRequest

  alias BlueJet.Inventory
  alias BlueJet.Storefront.Unlock
  alias BlueJet.Storefront.Customer

  schema "unlocks" do
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :account_id, Ecto.UUID
    field :unlockable_id, Ecto.UUID
    field :unlockable, :map, virtual: true

    timestamps()

    belongs_to :customer, Customer
  end

  def source(struct) do
    struct.sku || struct.unlockable
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Unlock.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Unlock.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields() -- [:status]
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :unlockable_id]
  end

  def required_fields do
    [:unlockable_id, :account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:unlockable, :customer])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_external_resources(unlock, :unlockable) do
    IO.inspect unlock
    unlockable = Inventory.do_get_unlockable(%AccessRequest{
      vas: %{ account_id: unlock.account_id },
      params: %{ id: unlock.unlockable_id }
    })

    %{ unlock | unlockable: unlockable }
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(u in query, where: u.account_id == ^account_id)
    end

    def default() do
      from(u in Unlock, order_by: [desc: u.inserted_at])
    end
  end
end
