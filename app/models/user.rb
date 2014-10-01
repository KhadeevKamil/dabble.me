class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  randomized_field :user_key, :length => 18, :prefix => 'u'

  has_many :entries, dependent: :destroy

  before_save { email.downcase! }

  serialize :frequency, Array

  after_create do
    send_welcome_email
    subscribe_to_mailchimp
  end

  def full_name_or_email
    first_name.present? ? "#{first_name} #{last_name}" : email
  end

  def first_name_or_settings
    first_name.present? ? "#{first_name}" : "Settings"
  end
  
  private

    def subscribe_to_mailchimp
      gb = Gibbon::API.new
      gb.lists.subscribe({
        :id => ENV['MAILCHIMP_LIST_ID'],
        :email => {:email => self.email},
        :merge_vars => {
          :FNAME => self.first_name,
          :LNAME => self.last_name,
          :GROUP => "Signed Up" },
        :double_optin => false})
    end

    def send_welcome_email
      UserMailer.welcome_email(self).deliver
    end

end