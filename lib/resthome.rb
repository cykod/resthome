# Copyright (C) Doug Youch

require 'httparty'

class RESTHome
  class Error < Exception; end
  class InvalidResponse < Error; end
  class MethodMissing < Error; end

  include HTTParty

  attr_accessor :base_uri, :basic_auth, :cookies
  attr_reader :response, :request_url, :request_options, :request_method

  # Defines a web service route
  #
  # === Arguments
  # *name* of the method to create
  # name has special meaning.
  # * If starts with create or add the method will be set to POST.
  # * If starts with edit or update the method will be set to PUT.
  # * If starts with delete the method will be set to DELETE.
  # * Else by default the method is GET.
  #
  # *path* is the path to the web service
  #
  # === Options
  #
  # [:method]
  #   The request method get/post/put/delete. Default is get.
  # [:expected_status]
  #   Expected status code of the response, will raise InvalidResponse. Can be an array of codes.
  # [:return]
  #   The method to call, the class to create or a Proc to call before method returns.
  # [:resource]
  #   The name of the element to return from the response.
  # [:no_body]
  #   Removes the body argument from a post/put route
  # [:query]
  #   Default set of query arguments
  def self.route(name, path, options={}, &block)
    args = path.scan /:[a-z_]+/
    path = "#{@path_prefix.join if @path_prefix}#{path}"
    function_args = args.collect{ |arg| arg[1..-1] }

    method = options[:method]
    expected_status = options[:expected_status]
    if method.nil?
      if name.to_s =~ /^(create|add|edit|update|delete)_/
        case $1
        when 'create'
          method = 'post'
          expected_status ||= [200, 201]
        when 'add'
          method = 'post'
          expected_status ||= [200, 201]
        when 'edit'
          method = 'put'
          expected_status ||= 200
        when 'update'
          method = 'put'
          expected_status ||= 200
        when 'delete'
          method = 'delete'
          expected_status ||= [200, 204]
        end
      else
        method = 'get'
        expected_status ||= 200
      end
    end

    method = method.to_s
    function_args << 'body' if (method == 'post' || method == 'put') && options[:no_body].nil?
    function_args << 'options={}, &block'

    method_src = <<-METHOD
    def #{name}(#{function_args.join(',')})
      path = "#{path}"
    METHOD

    args.each_with_index do |arg, idx|
      method_src << "path.sub! '#{arg}', #{function_args[idx]}.to_s\n"
    end

    if options[:no_body].nil?
      if method == 'post' || method == 'put'
        if options[:resource]
          method_src << "options[:body] = {'#{options[:resource].to_s}' => body}\n"
        else
          method_src << "options[:body] = body\n"
        end
      end
    end

    if options[:query]
      method_src << "options[:query] = #{options[:query].inspect}.merge(options[:query] || {})\n"
    end

    method_src << "request :#{method}, path, options\n"

    if expected_status
      if expected_status.is_a?(Array)
        method_src << 'raise InvalidResponse.new "Invalid response code #{response.code}" if ! [' + expected_status.join(',') + "].include?(response.code)\n"
      else
        method_src << 'raise InvalidResponse.new "Invalid response code #{response.code}" if response.code != ' + expected_status.to_s + "\n"
      end
    end

    return_method = 'nil'
    if options[:return].nil? || options[:return].is_a?(Proc)
      block ||= options[:return]
      if block
        register_route_block name, block
        return_method = "self.class.route_blocks['#{name}']"
      end
    elsif options[:return].is_a?(Class)
      return_method = options[:return].to_s
    else
      return_method = ":#{options[:return]}"
    end

    resource = options[:resource] ? "'#{options[:resource]}'" : 'nil'

    method_src << "parse_response!\n"

    method_src << "_handle_response response, :resource => #{resource}, :return => #{return_method}, &block\n"

    method_src << "end\n"

    if options[:instance]
      options[:instance].instance_eval method_src, __FILE__, __LINE__
    elsif options[:class]
      options[:class].class_eval method_src, __FILE__, __LINE__
    else
      self.class_eval method_src, __FILE__, __LINE__
    end
  end

  # Adds a route to the current object
  def route(name, path, options={})
    self.class.route name, path, options.merge(:instance => self)
  end

  def self.namespace(path_prefix)
    @path_prefix ||= []
    @path_prefix.push path_prefix
    yield
    @path_prefix.pop
  end

  # Creates routes for a RESTful API
  #
  # *resource_name* is the name of the items returned by the API,
  # *collection_name* is the plural name of the items,
  # *base_path* is the path to the collection
  #
  # Sets up 5 most common RESTful routes
  #
  # Example
  #  /customers.json GET list of customers, POST to create a customer
  #  /customers/1.json GET a customers, PUT to edit a customer, DELETE to delete a customer
  #  JSON response returns {'customer': {'id':1, 'name':'Joe', ...}}
  #
  # Setup the RESTful routes
  #  rest :customer, :customers, '/customers.json'
  #  # same as
  #  route :customers, '/customers.json', :resource => :customer
  #  route :create_customer, '/customers.json', :resource => :customer
  #  route :customer, '/customers/:customer_id.json', :resource => :customer
  #  route :edit_customer, '/customers/:customer_id.json', :resource => :customer
  #  route :delete_customer, '/customers/:customer_id.json', :resource => :customer
  #
  # Following methods are created
  #  customers # return an array of customers
  #  create_customer :name => 'Smith' # returns {'id' => 2, 'name' => 'Smith'}
  #  customer 1 # return data for customer 1
  #  edit_customer 1, :name => 'Joesph'
  #  delete_customer 1
  def self.rest(resource_name, collection_name, base_path, options={})
    options[:resource] ||= resource_name
    self.route collection_name, base_path, options
    self.route resource_name, base_path.sub(/(\.[a-zA-Z0-9]+)$/, "/:#{resource_name}_id\\1"), options
    self.route "edit_#{resource_name}", base_path.sub(/(\.[a-zA-Z0-9]+)$/, "/:#{resource_name}_id\\1"), options
    self.route "create_#{resource_name}", base_path, options
    self.route "delete_#{resource_name}", base_path.sub(/(\.[a-zA-Z0-9]+)$/, "/:#{resource_name}_id\\1"), options
  end

  # Creates the url
  def build_url(path)
    "#{self.base_uri || self.class.base_uri}#{path}"
  end

  # Adds the basic_auth and cookie options
  # This method should be overwritten as needed.
  def build_options!(options)
    options[:basic_auth] = self.basic_auth if self.basic_auth
    if @cookies
      options[:headers] ||= {}
      options[:headers]['cookie'] = @cookies.to_a.collect{|c| "#{c[0]}=#{c[1]}"}.join('; ') + ';'
    end
  end

  # Makes the request using HTTParty. Saves the method, path and options used.
  def request(method, path, options)
    build_options! options
    url = build_url path
    @request_method = method
    @request_url = url
    @request_options = options

    @response = self.class.send(method, url, options)
  end

  # Will either call edit_<name> or add_<name> based on wether or not the body[:id] exists.
  def save(name, body, options={})
    id = body[:id] || body['id']
    if id
      if self.class.method_defined?("edit_#{name}")
        self.send("edit_#{name}", id, body, options)
      elsif self.class.method_defined?("update_#{name}")
        self.send("update_#{name}", id, body, options)
      else
        raise MethodMissing.new "No edit/update method found for #{name}"
      end
    else
      if self.class.method_defined?("add_#{name}")
        self.send("add_#{name}", body, options)
      elsif self.class.method_defined?("create_#{name}")
        self.send("create_#{name}", body, options)
      else
        raise MethodMissing.new "No add/create method found for #{name}"
      end
    end
  end

  def method_missing(method, *args, &block) #:nodoc:
    if method.to_s =~ /^find_(.*?)_by_(.*)$/
      find_method = "find_#{$1}"
      find_args = $2.split '_and_'
      raise MethodMissing.new "Missing method #{find_method}" unless self.class.method_defined?(find_method)
      start = (self.method(find_method).arity + 1).abs
      options = args[-1].is_a?(Hash) ? args[-1] : {}
      options[:query] ||= {}
      find_args.each_with_index do |find_arg, idx|
        options[:query][find_arg] = args[start+idx]
      end

      if start > 0
        send_args = args[0..(start-1)]
        send_args << options
        return self.send(find_method, *send_args, &block)
      else
        return self.send(find_method, options, &block)
      end
    else
      super
    end
  end

  # Convenience method for saving all cookies by default called from parse_response!.
  def save_cookies!
    return unless @response.headers.to_hash['set-cookie']
    save_cookies @response.headers.to_hash['set-cookie']
  end

  # Parse an array of Set-cookie headers
  def save_cookies(data)
    @cookies ||= {}
    data.delete_if{ |c| c.blank? }.collect { |cookie| parts = cookie.split("\; "); parts[0] ? parts[0].split('=') : nil }.each do |c|
      @cookies[c[0].strip] = c[1].strip if c && c[0] && c[1]
    end
  end

  # Called after every valid request. Useful for parsing response headers.
  # This method should be overwritten as needed.
  def parse_response!
    save_cookies!
  end

  def self.route_blocks #:nodoc:
    {}
  end

  def self.register_route_block(route, proc) #:nodoc:
    blocks = self.route_blocks
    blocks[route.to_s] = proc

    sing = class << self; self; end
    sing.send :define_method, :route_blocks do 
      blocks
    end 
  end

  protected

  def _handle_response(response, opts={}, &block) #:nodoc:
    if response.is_a?(Array)
      response.to_a.collect do |obj|
        _handle_response_object obj, opts, &block
      end
    else
      _handle_response_object response, opts, &block
    end
  end

  def _handle_response_object(obj, opts={}) #:nodoc:
    obj = obj[opts[:resource]] unless opts[:resource].blank?
    if opts[:return]
      if opts[:return].is_a?(Class)
        obj = opts[:return].new obj
      elsif opts[:return].is_a?(Proc)
        obj = opts[:return].call obj
      else
        obj = send opts[:return], obj
      end
    end
    obj = yield(obj) if block_given?
    obj
  end
end
