require "uni_sender/version"
require 'uni_sender/camelize'
require 'net/http'
require 'json'

module UniSender

  class Client

    attr_accessor :api_key, :client_ip, :locale

    def initialize(api_key, params={})
      self.api_key = api_key
      params.each do |key, value|
        if defined?("#{key}=")
          self.send("#{key}=", value)
        end
      end
    end

    def locale
      @locale || 'en'
    end

    private

      def translate_params(params)
        params.inject({}) do |iparams, couple|
          iparams[couple.first] = case couple.last
          when String
            URI.encode(couple.last)
          when Array
            couple.last.map{|item| URI.encode(item.to_s)}.join(',')
          when Hash
            couple.last.each do |key, value|
              iparams["#{couple.first}[#{key}]"] = URI.encode(value.to_s)
              if value.is_a?(Hash)
                iparams.delete("#{couple.first}[#{key}]")
                value.each do |k,v|
                  iparams["#{couple.first}[#{key}][#{k}]"] = URI.encode(v.to_s)
                end
              end
            end
            nil
          else
            couple.last
          end
          iparams
        end
      end

      def method_missing(undefined_action, *args, &block)
        params = (args.first.is_a?(Hash) ? args.first : {} )
        if undefined_action == "importContacts"
          import_contacts(params)
        else
          default_request(undefined_action.to_s.camelize(false), params)
        end
      end

      def import_contacts(params)
        params = translate_params(params) if defined?('translate_params')
        params.merge!({'api_key'=>api_key, 'format'=>'json'})
        JSON.parse(Net::HTTP.post_form(URI.parse('http://api.unisender.com/ru/api/importContacts?format=json'),params).body)
      end

      def default_request(action, params={})
        params = translate_params(params) if defined?('translate_params')
        params.merge!({'api_key'=>api_key, 'format'=>'json'})
        query = make_query(params)
        url = URI("http://api.unisender.com/#{locale}/api/#{action}?#{query}")
        JSON.parse(Net::HTTP.get(url))
      end

      def make_query(params)
        params.map{|key, value| value.nil? ? "" : "#{key}=#{value}"}.reject(&:empty?).join('&')
      end

  end

end
