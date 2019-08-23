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
    @beneficiary_name = params[:beneficiary_name]
    @beneficiary_id = params[:beneficiary_id]
    @accounts = current_user.ledgers.map do |ledger|
      JSON.parse(RestClient.get("https://play.railsbank.com/v1/customer/ledgers/#{ledger.api_id}", headers))
    end
  end

  def create_transfer
    @sending_account = params[:account]
    @beneficiary = params[:beneficiary]
    @amount = params[:amount]
    to_upload = {
      ledger_from_id: @sending_account,
      beneficiary_id: @beneficiary,
      amount: @amount,
      payment_type: "payment-type-UK-FasterPayments"
    }
    response = RestClient.post("https://play.railsbank.com/v1/customer/transactions", to_upload.to_json, headers)
    transction = JSON.parse(response.body)
  end

  def choose_beneficiary
    response = RestClient.get("https://play.railsbank.com/v1/customer/beneficiaries?holder_id=#{current_user.enduser_id}", headers)
    @beneficiaries = JSON.parse(response.body)
  end

  def add_beneficiary
  end

  def account
  end

  def create_beneficiary
    @errors = {}
    to_upload = {
      holder_id: current_user.enduser_id,
      person: {
        name: beneficiary_params[:name],
        address: {
          address_refinement: beneficiary_params[:flat],
          address_number: beneficiary_params[:house_number],
          address_street: beneficiary_params[:street],
          address_city: beneficiary_params[:city],
          address_region: beneficiary_params[:region],
          address_postal_code: beneficiary_params[:post_code],
          address_iso_country: beneficiary_params[:country]
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
      @errors[:notice] = "Need to provide iban and bic swift or account_number and sort code"
      return render :add_beneficiary
    end
    begin
      response = RestClient.post("https://play.railsbank.com/v1/customer/beneficiaries", to_upload.to_json, headers)
      id = JSON.parse(response.body)[:beneficiary_id]
      redirect_to send_money_path + "?name=#{beneficiary_params[:name]}&id=#{id}"
    rescue => e
      puts e.response.body
    end
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
      redirect_to dashboard_path
    rescue => e
      puts e.reponse.body
    end
  end

  private

  def beneficiary_params
    params.require(:beneficiary).permit(:iban, :bic_swift, :sort_code, :account_number, :name, :flat, :house_number, :street, :city, :region, :post_code, :country)
  end
end
