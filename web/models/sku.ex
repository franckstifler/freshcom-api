defmodule BlueJet.Sku do
  @translatable_columns [:name, :caption, :description, :specification, :storage_description]

  use BlueJet.Web, :model
  use Trans, defaults: [container: :translations],
    translates: @translatable_columns

  alias BlueJet.Account

  schema "skus" do
    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string
    field :unit_of_measure, :string
    field :variable_weight, :boolean, default: false

    field :storage_type, :string
    field :storage_size, :integer
    field :stackable, :boolean, default: false

    field :caption, :string
    field :description, :string
    field :specification, :string
    field :storage_description, :string

    field :translations, :map, default: %{}

    field :translatable_columns, {:array, :atom}, default: @translatable_columns, virtual: true

    timestamps()

    belongs_to :avatar, BlueJet.ExternalFile
    belongs_to :account, Account
    has_many :external_file_collections, BlueJet.ExternalFileCollection
  end

  def translatable_columns do
    @translatable_columns
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, locale, params \\ %{}) do
    struct
    |> cast(params, [:code, :status, :name, :print_name, :unit_of_measure,
                     :variable_weight, :stackable, :storage_type, :storage_size,
                     :caption, :description, :specification, :storage_description,
                     :avatar_id])
    |> validate_length(:print_name, min: 8)
    |> validate_required([:status, :name, :print_name, :unit_of_measure])
    |> set_translations(params, struct.translations, @translatable_columns, locale)
  end

  def set_translations(changeset, params, old_translations, translatable_columns, locale) when locale !== "en" do
    t_fields = Enum.map_every(translatable_columns, 1, fn(item) -> Atom.to_string(item) end)
    nl_translations = old_translations
                    |> Map.get(locale, %{})
                    |> Map.merge(Map.take(params, t_fields))

    new_translations = Map.merge(old_translations, %{ locale => nl_translations })

    changeset = Enum.reduce(translatable_columns, changeset, fn(field_name, acc) -> Ecto.Changeset.delete_change(acc, field_name) end)
    Ecto.Changeset.put_change(changeset, :translations, new_translations)
  end
  def set_translations(changeset, _params, _old_translations, _translatable_columns, _locale), do: changeset
end
