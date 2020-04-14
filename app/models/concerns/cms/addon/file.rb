module Cms::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      define_model_callbacks :clone_files

      before_save :clone_files, if: ->{ try(:new_clone?) }
      before_save :save_files
      around_save :update_file_owners
      after_destroy :destroy_files

      after_generate_file :generate_public_files if respond_to?(:after_generate_file)
      after_remove_file :remove_public_files if respond_to?(:after_remove_file)
      after_merge_branch :update_owner_item_of_files rescue nil
    end

    def allow_other_user_files
      @allowed_other_user_files = true
    end

    def allowed_other_user_files?
      @allowed_other_user_files == true
    end

    def save_files
      add_ids = file_ids - file_ids_was.to_a

      ids = []
      files.each do |file|
        if !add_ids.include?(file.id)
          file.update(owner_item: self, state: state) if state_changed?
        elsif !allowed_other_user_files? && @cur_user && @cur_user.id != file.user_id
          next
        else
          file.update(site: site, model: model_name.i18n_key, owner_item: self, state: state)
          item = create_history_log(file)
          item.action = "update"
          item.save
        end
        ids << file.id
      end
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      del_ids.each do |id|
        file = SS::File.where(id: id).first
        if file
          file.skip_history_trash = skip_history_trash if [ file, self ].all? { |obj| obj.respond_to?(:skip_history_trash) }
          file.destroy
          item = create_history_log(file)
          item.action = "destroy"
          item.save
        end
      end

      file_ids = []
      self.column_values.each do |column_value|
        file_ids += column_value.all_file_ids
      end
      file_ids.compact!
      file_ids.uniq!

      file_ids_was = []
      column_values_was.each do |column_value|
        file_ids_was += column_value.all_file_ids
      end
      file_ids_was.compact!
      file_ids_was.uniq!

      add_ids = file_ids - file_ids_was

      files = SS::File.where(:id.in => add_ids)
      files.each do |file|
        item = create_history_log(file)
        item.action = "update"
        item.save
      end

      del_ids = file_ids_was - file_ids

      files = SS::File.where(:id.in => del_ids)
      files.each do |file|
        item = create_history_log(file)
        item.action = "destroy"
        item.save
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

    private

    def update_file_owners
      is_new = new_record?
      yield

      return if !is_new

      update_owner_item_of_files
    end

    def update_owner_item_of_files
      files.each do |file|
        file.update(owner_item: self)
      end
    end

    def create_history_log(file)
      History::Log.new(
        site_id: site.id,
        user_id: user.id,
        session_id: Rails.application.current_session_id,
        request_id: Rails.application.current_request_id,
        controller: self.model_name.i18n_key,
        url: file.url
      )
    end
  end
end
