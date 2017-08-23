module Uploader
  module Helpers
    class FieldTag
      RESERVED_OPTIONS_KEYS = %(method_name object_name theme value object sortable).freeze

      attr_reader :template, :object, :theme

      delegate :uploader, to: :template

      # Wrapper for render uploader field
      # Usage:
      #
      #   uploader = FieldTag.new(object_name, method_name, template, options)
      #   uploader.render
      #
      def initialize(object_name, method_name, template, options = {}) #:nodoc:
        @options = { object_name: object_name, method_name: method_name }.merge(options)
        @template = template
        @attachment_id = options[:attachment_id]

        @theme = (@options.delete(:theme) || 'default')
        @value = @options.delete(:value) if @options.key?(:value)

        @object = @options.delete(:object) if @options.key?(:object)
        @object ||= @template.instance_variable_get("@#{object_name}")
      end

      def render(locals = {}) #:nodoc:
        locals = { field: self }.merge(locals)
        @template.render(partial: "uploader/#{@theme}/container", locals: locals)
      end

      def id
        @id ||= @template.dom_id(@object, [method_name, 'uploader'].join('_'))
      end

      def method_name
        @options[:method_name]
      end

      def object_name
        @options[:object_name]
      end

      def multiple?
        @object.fileupload_multiple?(method_name)
      end

      def value
        @value ||= @object.fileupload_asset(method_name)
      end

      def values
        Array.wrap(value)
      end

      def exists?
        values.map(&:persisted?).any?
      end

      def sortable?
        @options[:sortable] == true
      end

      def klass
        @klass ||= @object.fileupload_klass(method_name)
      end

      def attachments_path(options = {})
        options = @object.fileupload_params(method_name).merge(options)
        options[:attachment_id] = @attachment_id
        uploader.attachments_path(options)
      end

      def input_html
        @input_html ||= { multiple: multiple?, class: 'uploader' }.merge(input_html_options)
        @input_html[:data] ||= {}
        @input_html[:data][:url] ||= attachments_path(@input_html)
        @input_html
      end

      def input_html_options
        @options.select { |key, _value| !RESERVED_OPTIONS_KEYS.include?(key.to_s) }
      end
    end
  end
end
