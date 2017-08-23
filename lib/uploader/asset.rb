require 'active_support/concern'

module Uploader
  module Asset
    extend ActiveSupport::Concern

    module ClassMethods
      def fileupload_find_asset(params)
        where(id: params[:id]).first
      end

      def fileupload_find_assets(params)
        conditions = fileupload_assetable_options(params)

        if params[:assetable_id].blank? && !params[:guid].blank?
          conditions[Uploader.guid_column] = params[:guid]
        end

        where(conditions)
      end

      def fileupload_assetable_options(params)
        h = {
          "#{Uploader.assetable_column}_type" => params[:assetable_type],
          "#{Uploader.assetable_column}_id" => params[:assetable_id],
        }
        h['attachment_id'] = params['attachment_id'] if params['attachment_id'].present?
        h
      end

      def fileupload_update_ordering(params)
        return if params[:assets].blank?

        Array(params[:assets]).each_with_index do |id, index|
          where(id: id).update_all(sort_order: index)
        end
      end
    end

    # Save asset
    # Usage:
    #
    #   class Asset < ActiveRecord::Base
    #     include Uploader::Asset
    #
    #     def fileupload_create(params, request = nil)
    #       self.user = request.env['warden'].user
    #       super
    #     end
    #   end
    #
    def fileupload_create(params, _request = nil)
      self[Uploader.guid_column] = params[:guid]
      update_attributes(self.class.fileupload_assetable_options(params))
    end

    # Destroy asset
    # Usage (cancan example):
    #
    #   class Asset < ActiveRecord::Base
    #     include Uploader::Asset
    #
    #     def fileupload_destroy(params, request = nil)
    #       ability = Ability.new(request.env['warden'].user)
    #       if ability.can? :delete, self
    #         super
    #       else
    #         errors.add(:id, :access_denied)
    #       end
    #     end
    #   end
    #
    def fileupload_destroy(_params, _request = nil)
      destroy
    end

    # Serialize asset to fileupload JSON format
    #
    def to_fileupload
      {
        id: id,
        name: filename,
        content_type: content_type,
        size: size,
        url:  url,
        thumb_url: thumb_url
      }
    end
  end
end
