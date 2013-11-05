module Polytexnic
  class Railtie < ::Rails::Railtie
    initializer :assets do |config|
      path = File.expand_path(File.join(File.dirname(__FILE__),
        "..", "template", "html", "stylesheets"))
      Rails.application.config.assets.paths << path
    end
  end
end