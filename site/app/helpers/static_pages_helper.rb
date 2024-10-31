module StaticPagesHelper
  def anchored_header(tag, title)
    id = title.parameterize
    content_tag tag, link_to(title, anchor: id), id: id
  end

  def store_path(ref, platform: nil)
    "/store?ref=#{ref}#{"&platform=#{platform}" if platform}"
  end
end
