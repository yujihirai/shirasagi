module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Gws::User }

    helper Gws::LayoutHelper

    before_action :validate_gws
    before_action :set_gws_assets
    before_action :set_current_site
    before_action :set_gws_logged_in, if: ->{ @cur_user }
    before_action :save_controller_access_history, if: ->{ @cur_user }
    before_action :set_current_group, if: ->{ @cur_user }
    before_action :set_account_menu, if: ->{ @cur_user }
    before_action :set_crumbs
    navi_view "gws/main/navi"
  end

  private

  def validate_gws
    raise '404' if SS.config.gws.disable.present?
  end

  def set_gws_assets
    SS.config.gws.stylesheets.each { |m| stylesheet(m) }
    SS.config.gws.javascripts.each { |m| javascript(m) }
  end

  def set_current_site
    @ss_mode = :gws
    @cur_site = Gws::Group.find params[:site]
    @cur_user.cur_site = @cur_site if @cur_user
    @crumbs << [@cur_site.name, gws_portal_path]
  end

  def set_current_group
    @cur_group = @cur_user.gws_default_group
    raise "403" unless @cur_group
  end

  def set_account_menu
    @account_menu = []
    @cur_user.groups.in_group(@cur_site).each do |group|
      next if @cur_user.gws_default_group.id == group.id
      @account_menu << [group.section_name, gws_default_group_path(default_group: group)]
    end
    @account_menu << [I18n.t("mongoid.models.gws/user_setting"), gws_user_setting_path]
  end

  def save_controller_access_history
    Gws::History.notice!(
      :controller, @cur_user, @cur_site,
      path: request.path, controller: self.class.name.underscore, action: action_name, message: 'accessed'
    ) rescue nil
  end

  def set_gws_logged_in
    gws_session = session[:gws]
    gws_session ||= {}
    gws_session['last_logged_in'] ||= begin
      Gws::History.info!(
        :controller, @cur_user, @cur_site,
        path: request.path, controller: self.class.name.underscore, action: action_name, message: 'logged in'
      ) rescue nil

      Time.zone.now.to_i
    end

    session[:gws] = gws_session
  end

  def set_crumbs
    #
  end

  def current_site
    @cur_site
  end

  def current_group
    @cur_group
  end
end
