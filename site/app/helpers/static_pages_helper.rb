module StaticPagesHelper
  def store_path(ref, platform: nil)
    "/store?ref=#{ref}#{"&platform=#{platform}" if platform}"
  end
end
