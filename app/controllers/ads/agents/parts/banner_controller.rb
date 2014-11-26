class Ads::Agents::Parts::BannerController < ApplicationController
  include Cms::PartFilter::View

  public
    def index
      @node = @cur_part.parent
      return render nothing: true unless @node

      sort = @node.becomes_with_route.sort_hash
      @random = sort[:random]

      @items = Ads::Banner.site(@cur_site).public(@cur_date).order_by(sort)
      #@items = @items.shuffle if @random
    end
end
