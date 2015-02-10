# encoding: utf-8

module CartoDB
  module PlatformLimits

    # Abstract limit class, providing scaffolding.
    # TODO: Scenarios:
    # - user id
    # - user ip
    # - user id AND ip
    # Context options:
    # - file/int/Datasource
    # - table/table-rows-count/table-feature-size
    # - action
    class AbstractLimit

      TYPE_USER = 'u'
      TYPE_IP = 'i'

      def self.classname
        self.name.gsub(/.*::/, '').to_sym
      end

      # Class constructor
      # @param options Hash { :user, :ip, :initial_value, :max_value, :ttl }
      # @throws ArgumentError
      def initialize(options={})
        @user = options.fetch(:user, nil)
        @ip = options.fetch(:ip, nil)
        raise ArgumentError.new('options must be a Hash') unless options.is_a?(Hash)
        raise ArgumentError.new('Must supply at least user id or IP address') if @user.nil? && @ip.nil?

        @initial_value = options.fetch(:initial_value, nil)
        @max_value = options.fetch(:max_value, nil)
        @time_frame = options.fetch(:ttl, nil)
      end

      # Loads current value from the backend (ttl will be fetched on-demand)
      def load
        raise "Implement at child classes"
      end

      # Checks if user is over limit, increasing the internal counter (where proceeds)
      # @param context mixed|nil
      # @return bool
      def is_over_limit!(context=nil)
        increase
        is_over_limit(context)
      end

      # Checks if user is over limit without increasing the internal counter
      # @param context mixed|nil
      # @return bool
      def is_over_limit?(context=nil)
        is_over_limit(context)
      end

      # Checks if user is within the allowed limit, increasing the internal counter (where proceeds)
      # @param context mixed|nil
      # @return bool
      def is_within_limit!(context=nil)
        !is_over_limit!(context)
      end

      # Checks if user is within the allowed limit without increasing the internal counter
      # @param context mixed|nil
      # @return bool
      def is_within_limit?(context=nil)
        !is_over_limit?(context)
      end

      # Peeks the current value of the limit without increasing the internal counter
      # @param context mixed|nil
      # @return mixed
      def peek(context=nil)
        get(context)
      end

      # Gets (where proceeds) the remaining count for the limit
      # Useful for a "X-Rate-Limit-Remaining" header
      # @param context mixed|nil
      # @return mixed|nil
      def remaining_limit?(context=nil)
        max = get_maximum(context)
        current = get(context)
        (max.nil? || current.nil?) ? nil : max - current
      end

      # Gets (where proceeds) the maximum value until hitting the limit
      # Useful for a "X-Rate-Limit-Limit" header
      # @param context mixed|nil
      # @return mixed|nil
      def maximum_limit?(context=nil)
        get_maximum(context)
      end

      # Gets (where proceeds) the timestamp when the limit will expire/reset
      # Useful for a "X-Rate-Limit-Reset" header
      # @param context mixed|nil
      # @return integer|nil
      def time_period?(context=nil)
        get_time_period(context)
      end

      # Returns the key for this limit instance
      # e.g. limits:Importer:InputFileSize:u:cartodb_user
      # e.g. limits:Security::LoginAttempts:ui:cartodb_user127.0.0.1
      # @return string
      def key
        "limits:#{subkey}:#{user_ip_key_fragment}"
      end

      # TODO: Revisit this methods, might not be needed hidden and just provided with default logic and overriden
      protected

      attr_accessor :user, :ip, :initial_value, :max_value, :time_frame, :current_value

      # Builds the subkey part that identifies current limit
      # Must have format 'xxx:yyy' Where xxx is the limit group and yyy the limit name.
      # e.g. Importer:InputFileSize
      def subkey
        raise "Implement at child classes"
      end

      # @param context mixed
      # @return bool
      def is_over_limit(context)
        raise "Implement at child classes"
      end

      # Gets current value of the limit
      # @param context mixed
      # @return mixed
      def get(context)
        raise "Implement at child classes"
      end

      # Gets the maximum limit value
      # @param context mixed
      # @return mixed
      def get_maximum(context)
        raise "Implement at child classes"
      end

      # Gets when the limit expires
      # @param context mixed
      # @return integer|nil Timestamp
      def get_time_period(context)
        raise "Implement at child classes"
      end

      # Increases the limit
      # @param amount integer
      def increase(amount=1)
        raise "Implement at child classes"
      end

      # Decreases the limit
      # @param amount integer
      def decrease(amount=1)
        raise "Implement at child classes"
      end

      # Sets the limit to a specific value
      # @param value mixed
      def set(value)
        raise "Implement at child classes"
      end

      # Resets the limit
      def expire
        raise "Implement at child classes"
      end

      private

      # Builds the key fragment that indicates if limit is based on user, ip or both (and their values)
      # @return string
      def user_ip_key_fragment
        type_fragment = ''
        value_fragment = ''
        unless @user.nil?
          type_fragment << TYPE_USER
          value_fragment << @user
        end
        unless @ip.nil?
          type_fragment << TYPE_IP
          value_fragment << @ip.to_s
        end

        "#{type_fragment}:#{value_fragment}"
      end

    end

  end
end
