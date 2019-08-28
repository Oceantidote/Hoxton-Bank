class UsersController < ApplicationController

  def dashboard
    ledger_response = RestClient.get("https://play.railsbank.com/v1/customer/ledgers?holder_id=#{current_user.enduser_id}", headers)
    @ledgers = JSON.parse(ledger_response.body)
    @accounts = []
    @ledgers.each do |ledger|
      transaction_response = RestClient.get("https://play.railsbank.com/v1/customer/ledgers/#{ledger['ledger_id']}/entries", headers)
      transactions = []
      transactions = JSON.parse(transaction_response.body).map do |trans|
        get_transaction(trans["transaction_id"])
      end
      @accounts << { uk_id: ledger["uk_account_number"], ledger: ledger, transactions: transactions }
    end
  end

  def send_money
    @beneficiary_name = params["beneficiary"] ? params["beneficiary"]["person"]["name"] : params["name"]
    @beneficiary_id = params["beneficiary"] ? params["beneficiary"]["beneficiary_id"] : params["beneficiary_id"]
    @sort = params['beneficiary'] ? params['beneficiary']["uk_sort_code"] : params['sort']
    @account = params['beneficiary'] ? params['beneficiary']["uk_account_number"] : params['account']
    @accounts = current_user.ledgers.map do |ledger|
      JSON.parse(RestClient.get("https://play.railsbank.com/v1/customer/ledgers/#{ledger.api_id}", headers))
    end
  end

  def create_transfer
    @ledger_id = params[:account]
    @beneficiary_id = params[:beneficiary]
    @amount = params[:amount]
    to_upload = {
      ledger_from_id: @ledger_id,
      beneficiary_id: @beneficiary_id,
      amount: @amount,
      payment_type: "payment-type-UK-FasterPayments"
    }
    begin
      response = RestClient.post("https://play.railsbank.com/v1/customer/transactions", to_upload.to_json, headers)
      transaction = JSON.parse(response.body)
      to_upload[:name] = params[:name]
      to_upload[:transaction_id] = transaction["transaction_id"]
      redirect_to sent_confirmation_path(to_upload)
    rescue => e
      puts e.response.body
    end
  end

  def choose_beneficiary
    response = RestClient.get("https://play.railsbank.com/v1/customer/beneficiaries?holder_id=#{current_user.enduser_id}", headers)
    @beneficiaries = JSON.parse(response.body)
  end

  def add_beneficiary
    @errors = {}
  end

  def account
  end

  def create_beneficiary
    @errors = {}
    to_upload = {
      holder_id: current_user.enduser_id,
      person: {
        name: beneficiary_params[:name]
      },
      default_account: {
        asset_class: "currency",
      }
    }
    if beneficiary_params[:account_number].present? && beneficiary_params[:sort_code].present?
      to_upload[:default_account][:account_number] = beneficiary_params[:account_number]
      to_upload[:default_account][:bank_code] = beneficiary_params[:sort_code]
      to_upload[:default_account][:asset_type] = "gbp"
      to_upload[:default_account][:bank_code_type] = "sort-code"
    else
      @errors[:notice] = "Please enter account number and sort-code"
      return render :add_beneficiary
    end
    begin
      response = RestClient.post("https://play.railsbank.com/v1/customer/beneficiaries", to_upload.to_json, headers)
      id = JSON.parse(response.body)["beneficiary_id"]
      redirect_to send_money_path + "?name=#{beneficiary_params[:name]}&beneficiary_id=#{id}&account=#{beneficiary_params[:account_number]}&sort=#{beneficiary_params[:sort_code]}"
    rescue => e
      puts e.response.body
    end
  end

  def sent_confirmation
    id = params["transaction_id"]
    sleep(0.3)
    @transaction = get_transaction(id)
    ledger_id = @transaction["from_ledger_id"]
    begin
      response = RestClient.get("https://play.railsbank.com/v1/customer/ledgers/#{ledger_id}", headers)
      @ledgers = JSON.parse(response.body)
      @ledger = @ledgers.select{|ledger| ledger["ledger_holder"]["enduser_id"] == current_user["enduser_id"]}.first
    rescue => e
      puts e.response.body
    end
    if @transaction["transaction_status"] == "transaction-status-pending"
      render :sent_confirmation
    end
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
      sleep(1)
      redirect_to dashboard_path
    rescue => e
      puts e.reponse.body
    end
  end

  private

  def get_transaction(id)
    begin
      response = RestClient.get("https://play.railsbank.com/v1/customer/transactions/#{id}", headers)
      JSON.parse(response.body)
    rescue => e
      puts e.response.body
    end
  end

  def beneficiary_params
    params.require(:beneficiary).permit(:iban, :bic_swift, :sort_code, :account_number, :name, :flat, :house_number, :street, :city, :region, :post_code, :country)
  end
end


























