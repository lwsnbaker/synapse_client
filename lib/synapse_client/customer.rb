
module SynapseClient
  class Customer < APIResource

    attr_accessor :email, :fullname, :phonenumber, :ip_address
    attr_accessor :access_token, :refresh_token, :expires_in
    attr_accessor :username

    def initialize(options = {})
      @id            = options[:id]            || options[:user_id]
      @email         = options[:email]
      @fullname      = options[:fullname]      || options[:name]
      @phonenumber   = options[:phonenumber]   || options[:phone_number]
      @ip_address    = options[:ip_address]

      @access_token  = options[:access_token]
      @refresh_token = options[:refresh_token]
      @expires_in    = options[:expires_in]
      @username      = options[:username]
    end

    def self.api_resource_name
      "user" # see README.md
    end

    def self.create(opts={})
      Customer.new(opts).create
    end

    def create
      headers  = {"REMOTE_ADDR" => @ip_address}
      response = SynapseClient.request(:post, url + "create", to_hash, headers)

      return response unless response.successful?
      update_attributes(response.data)
    end

    def self.retrieve(access_token)
      response = SynapseClient.request(:post, url + "show", {:access_token => access_token})

      return response unless response.successful?
      Customer.new(response.data.user)
    end

    # TODO
    def login
      # use http://synapsepay.readme.io/v1.0/docs/authentication-login
    end

    def add_bank_account(params={})
      BankAccount.add(params.merge({
        :access_token => @access_token,
        :fullname     => @fullname
      }))
    end

    def link_bank_account(params={})
      BankAccount.link(params.merge({
        :access_token => @access_token
      }))
    end

=begin
    def link_account(options = {}, client)
      options.to_options!.compact

      data = {
        :bank               => options[:bank_name],
        :password           => options[:password],
        :pin                => options[:pin] || "1234",
        :username           => options[:username]
      }

      request  = SynapseClient::Request.new("/api/v2/bank/login/", data, client)
      response = request.post

      if response.instance_of?(SynapseClient::Error)
        response
      elsif response["is_mfa"]
        SynapseClient::MFA.new(response["response"])
      else
        add_bank_accounts response["banks"]
        @bank_accounts
      end
    end
    def unlink_account(options = {}, client)
      data = {
        :bank_id => options.delete(:bank_id),
      }

      request  = SynapseClient::Request.new("/api/v2/bank/delete/", data, client)
      request.post
    end
=end

    def bank_accounts
      BankAccount.all({:access_token => @access_token})
    end
    def primary_bank_account
      @bank_accounts.select{|ba| ba.is_buyer_default}.first
    end


private
    def update_attributes(data)
      @access_token  = data.access_token
      @refresh_token = data.refresh_token
      @expires_in    = data.expires_in
      @username      = data.username
      return self
    end

  end
end
