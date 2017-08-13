defmodule BlueJet.Storefront.Price do
  use BlueJet, :data

  use Trans, translates: [:name, :caption], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Identity.Account

  schema "prices" do
    field :status, :string
    field :name, :string
    field :label, :string
    field :caption, :string
    field :currency_code, :string, default: "CAD"
    field :charge_cents, Money.Ecto.Type
    field :estimate_average_ratio, :decimal
    field :estimate_maximum_ratio, :decimal
    field :minimum_order_quantity, :integer, default: 1
    field :order_unit, :string
    field :charge_unit, :string
    field :public_orderable, :boolean, default: true
    field :estimate_by_default, :boolean, default: false
    field :tax_one_rate, :integer, default: 0
    field :tax_two_rate, :integer, default: 0
    field :tax_three_rate, :integer, default: 0
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :product_item, ProductItem
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Price.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Price.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_fields do
    [:account_id, :status, :label, :currency_code, :charge_cents, :order_unit, :charge_unit]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> validate_assoc_account_scope(:product_item)
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

  def query_for(product_item_id: product_item_id, order_quantity: order_quantity) do
    query = from p in Price,
      where: p.product_item_id == ^product_item_id,
      where: p.minimum_order_quantity <= ^order_quantity,
      order_by: [desc: p.minimum_order_quantity]

    query |> first()
  end
  def query_for(product_item_ids: product_item_ids, order_quantity: order_quantity) do
    query = from p in Price,
      select: %{ row_number: fragment("ROW_NUMBER() OVER (PARTITION BY product_item_id ORDER BY minimum_order_quantity DESC)"), id: p.id },
      where: p.product_item_id in ^product_item_ids,
      where: p.minimum_order_quantity <= ^order_quantity

    query = from pp in subquery(query),
      join: p in Price, on: pp.id == p.id,
      where: pp.row_number == 1,
      select: p

    query
  end
end