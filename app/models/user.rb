class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_create :create_default_end_user

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name}#{middle_name.present? ? ' ' + middle_name : ''} #{last_name}"
  end

  private

  def create_default_end_user
    payload = {
      person: {
        name: full_name,
        email: email
      }
    }

    headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "API-Key #{ENV['RAILS_BANK_API_KEY']}"
    }

    response = RestClient.post('https://play.rails.com/customer/endusers', payload.to_json, headers)
    body = JSON.parse(response.body)
    self[:enduser_id] = body[:enduser_id]
    create_default_ledger
  end

  def create_default_ledger
    payload = {
      asset_class: 'currency',
      asset_type: 'gbp',
      holder_id: enduser_id,
      ledger_primary_use_types:  ['ledger-primary-use-types-deposit', 'ledger-primary-use-types-payments'],
      ledger_t_and_cs_country_of_jurisdiction: 'GBR',
      ledger_type: 'ledger-type-single-user',
      ledger_who_owns_assets: 'ledger-assets-owned-by-me',
      partner_product: 'ExampleBank-GBP-1'
    }

    headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "API-Key #{ENV['RAILS_BANK_API_KEY']}"
    }

    response = RestClient.post('https://play.rails.com/customer/ledgers', payload.to_json, headers)
    body = JSON.parse(response.body)
    Ledger.create(user: self, api_id: body['ledger_id']
  end
end
