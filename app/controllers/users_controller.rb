class UsersController < ApplicationController

  def dashboard
    ledger_response = RestClient.get("https://play.railsbank.com/v1/customer/ledgers?holder_id=#{current_user.enduser_id}", headers)
    @ledgers = JSON.parse(ledger_response.body)
    @accounts = []
    @ledgers.each do |ledger|
      transaction_response = RestClient.get("https://play.railsbank.com/v1/customer/ledgers/#{ledger['ledger_id']}/entries", headers)
      @accounts << { uk_id: ledger["uk_account_number"], ledger: ledger, transactions: JSON.parse(transaction_response.body) }
    end
  end

  def send_money
  end

  def create_transfer
    @beneficiary = params[:beneficiary]
  end

  def choose_beneficiary
    response = RestClient.get("https://play.railsbank.com/v1/customer/beneficiaries?holder_id=#{current_user.enduser_id}")
    @beneficiaries = JSON.parse(response.body)
  end

  def add_beneficiary
  end

  def account
  end

  def create_beneficiary
    to_upload = {
      holder_id: current_user.enduser_id,
      person: {
        name: beneficiary_params[:name],
        address: {
          address_refinement: params[:flat],
          address_number: params[:house_number],
          address_street: params[:street],
          address_city: params[:city],
          address_region: params[:region],
          address_postal_code: params[:post_code],
          address_iso_country: params[:country]
        }
      }
    }
    if beneficiary_params[:account_number].present? && beneficiary_params[:sort_code].present?
      to_upload[:uk_account_number] = beneficiary_params[:account_number]
      to_upload[:uk_sort_code] = beneficiary_params[:sort_code]
    elsif beneficiary_params[:iban].present? && beneficiary_params[:bic_swift].present?
      to_upload[:iban] = beneficiary_params[:iban]
      to_upload[:bic_swift] = beneficiary_params[:bic_swift]
    else
      return render :add_beneficiary, notice: "Need to provide iban and bic swift or account_number and sort code"
    end
    response = JSON.post("https://play.railsbank.com/v1/customer/beneficiaries", to_upload.to_json, headers)
    id = JSON.parse(response.body)[:beneficiary_id]
    redirect_to send_money_path + "?name=#{beneficiary_params[:name]}&id=#{id}"
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

    begin
      response = RestClient.post('https://play.railsbank.com/v1/customer/ledgers', payload.to_json, headers)
      body = JSON.parse(response.body)
      Ledger.create(user: current_user, api_id: body['ledger_id'])
    rescue => e
      puts e.reponse.body
    end
  end

  private

  def beneficiary_params
    params.require(:beneficiary).permit(:iban, :bic_swift, :sort_code, :account_number, :name, :flat, :house_number, :street, :city, :region, :post_code, :country)
  end
end
