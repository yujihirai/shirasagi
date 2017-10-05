class Gws::Workflow::Column
  include SS::Document
  include Gws::Addon::CustomField
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Workflow::Form

  input_type_include_upload_file

  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :name)
      end

      criteria
    end
  end

  def validate_value(record, attribute, hash)
    value = record.read_custom_value(self)
    if required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    if value.present?
      if %w(radio_button select).include?(input_type)
        unless select_options.include?(value)
          record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
        end
      end
      if input_type == 'check_box'
        value = [ value ].flatten.compact.select(&:present?)
        if (value - select_options).present?
          record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
        end
      end
      if input_type == 'upload_file' && value.is_a?(ActionDispatch::Http::UploadedFile)
        if value.size > max_upload_file_size
          record.errors.add :base, "#{name}#{I18n.t(
            'errors.messages.too_large_file',
            filename: value.original_filename,
            size: ApplicationController.helpers.number_to_human_size(value.size),
            limit: ApplicationController.helpers.number_to_human_size(max_upload_file_size))}"
        end
      end
    end
  end
end
