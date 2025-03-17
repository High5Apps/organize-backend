module ApplicationHelper
  SITE_TITLE = 'Organize: Modern Labor Unions'
  SITE_TITLE_SHORT = 'Organize'

  def canonical_url
    full_url_for host: 'getorganize.app', port: nil, protocol: 'https'
  end

  def site_title
    # Subtract 3 more for ' | ' between site and page title
    (title&.size || 0) > (MetaTags.config.title_limit - SITE_TITLE.length - 3) ?
      SITE_TITLE_SHORT : SITE_TITLE
  end
end
