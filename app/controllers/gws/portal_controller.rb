class Gws::PortalController < ApplicationController
  include Gws::BaseFilter
  helper Gws::Schedule::PlanHelper

  private
    def set_crumbs
      @crumbs << [:"gws.portal", gws_portal_path]
    end

  public
    def index
      @users = @cur_group.users
    end
end
