module Cms::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      before_save :clone_files, if: ->{ try(:new_clone?) }
      before_save :save_files
      after_destroy :destroy_files

      after_generate_file :generate_public_files, if: ->{ serve_static_relation_files? }
      after_remove_file :remove_public_files
    end

    def allow_other_user_files
      @allowed_other_user_files = true
    end

    def allowed_other_user_files?
      @allowed_other_user_files == true
    end

    def save_files
      return true unless file_ids_changed?

      add_ids = file_ids - file_ids_was.to_a

      ids = []
      files.each do |file|
        if !add_ids.include?(file.id)
          #
        elsif !allowed_other_user_files? && @cur_user && @cur_user.id != file.user_id
          next
        else
          file.add_thumb_size([120, 90]) if file.image?
          file.update_attributes(site_id: site_id, model: model_name.i18n_key, state: "public")
        end
        ids << file.id
      end
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      del_ids.each do |id|
        file = SS::File.where(id: id).first
        file.destroy if file
      end
    end

    def destroy_files
      files.destroy_all
    end

    def generate_public_files
      files.each do |file|
        file.generate_public_file
      end
    end

    def remove_public_files
      files.each do |file|
        file.remove_public_file
      end
    end
  end
end
