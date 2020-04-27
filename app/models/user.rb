class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_create :create_default_end_user

  validates :first_name, :last_name, presence: true
  has_many :ledgers, dependent: :destroy

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
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "API-Key #{ENV['API_KEY'] + '#' + ENV['API_KEY_TWO']}"
    }
    response = RestClient.post('https://play.railsbank.com/v1/customer/endusers', payload.to_json, headers)
    body = JSON.parse(response.body)
    self[:enduser_id] = body['enduser_id']
  end
end
