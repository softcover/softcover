module Softcover
  class Railtie < ::Rails::Railtie
    initializer "softcover", group: :all do |app|
      path = File.expand_path(File.join(File.dirname(__FILE__),
        "..", "book_template", "html", "stylesheets"))
      app.config.assets.paths << path
    end
  end
end