class UsersController < ApplicationController

  def dashboard
  end

  def send_money
  end

  def create_transfer
  end

  def choose_beneficiary
  end

  def add_beneficiary
  end

  def account
  end

  def create_beneficiary
  end

  def sent_confirmation
  end

  def creation
    payload = {
      asset_class: 'currency',
      asset_type: 'gbp',
      holder_id: current_user.enduser_id,
      ledger_primary_use_types:  ['ledger-primary-use-types-deposit', 'ledger-primary-use-types-payments'],
      ledger_t_and_cs_country_of_jurisdiction: 'GBR',
      ledger_type: 'ledger-type-single-user',
      ledger_who_owns_assets: 'ledger-assets-owned-by-me',
      partner_product: 'ExampleBank-GBP-1'
    }

    headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "API-Key #{ENV['RAILS_BANK_API_KEY']}##{ENV['RAILS_BANK_SECRET_PATTERN']}"
    }
    begin
      response = RestClient.post('https://play.railsbank.com/v1/customer/ledgers', payload.to_json, headers)
      body = JSON.parse(response.body)
      Ledger.create(user: current_user, api_id: body['ledger_id'])
    rescue => e
      puts e.reponse.body
    end
  end
end
