cache_path = Rails.public_path.join "cached_pages"

# Remove any previously cached pages
FileUtils.rm_r Dir["#{cache_path}/*"]

Rails.application.config.action_controller.page_cache_directory = cache_path
