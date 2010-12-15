require 'resthome'
require 'json'

class ChargifyWebService < RESTHome

  headers 'Content-Type' => 'application/json'

  rest :customer, :customers, '/customers.json'
  route :find_customer, '/customers/lookup.json', :resource => 'customer'
  # find_customer_by_reference
  route :customer_subscriptions, '/customers/:customer_id/subscriptions.json', :resource => :subscription

  route :product_families, '/product_families.xml', :resource => :product_families

  route :products, '/products.json', :resource => :product
  route :product, '/products/:product_id.json', :resource => :product
  route :find_product_by_handle, '/products/handle/:handle.json', :resource => :product

  rest :subscription, :subscriptions, '/subscriptions.json'
  route :cancel_subscription, '/subscriptions/:subscription_id.json', :resource => :subscription, :method => :delete, :expected_status => [200, 204]
  route :reactivate_subscription, '/subscriptions/:subscription_id/reactivate.xml', :resource => :subscription, :method => :put, :expected_status => 200
  route :subscription_transactions, '/subscriptions/:subscription_id/transactions.json', :resource => :transaction
  # Chargify offers the ability to upgrade or downgrade a Customer's subscription in the middle of a billing period.
  route :create_subscription_migration, '/subscriptions/:subscription_id/migrations.json', :expected_status => 200
  route :reactivate_subscription, '/subscriptions/:subscription_id/reactivate.xml', :resource => :subscription, :method => :put, :expected_status => 200
  route :create_subscription_credit, '/subscriptions/:subscription_id/credits.json', :resource => :credit
  route :reset_subscription_balance, '/subscriptions/:subscription_id/reset_balance.xml', :resource => :subscription, :method => :put, :expected_status => 200

  route :transactions, '/transactions.json', :resource => :transaction

  route :create_charge, '/subscriptions/:subscription_id/charges.json', :resource => :charge

  route :components, '/product_families/:product_family_id/components.json', :resource => :component
  route :component_usages, '/subscriptions/:subscription_id/components/:component_id/usages.json', :resource => :usage
  route :create_component_usage, '/subscriptions/:subscription_id/components/:component_id/usages.json', :resource => :usage, :expected_status => 200

  route :coupon, '/product_families/:product_family_id/coupons/:coupon_id.json', :resource => :coupon
  route :find_coupon, '/product_families/:product_family_id/coupons/find.json', :resource => :coupon
  # find_coupon_by_code

  route :subscription_components, '/subscriptions/:subscription_id/components.json', :resource => :component
  route :edit_subscription_component, '/subscriptions/:subscription_id/components/:component_id.json', :resource => :component

  def initialize(api_key, subdomain)
    self.base_uri = "https://#{subdomain}.chargify.com"
    self.basic_auth = {:username => api_key, :password => 'x'}
  end

  def build_options!(options)
    super
    options[:body] = options[:body].to_json if options[:body]
  end

  def parse_response!; end
end
