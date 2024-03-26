# frozen_string_literal: true

require "fileutils"

module Calagator
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    class_option :test_app, type: :boolean, default: false

    def install
      add_route
      add_yaml_config
      add_initializers
      add_javascripts
      add_stylesheets
      add_devise_views
      add_assets
      add_seeds
      run "rm -f public/index.html"
      unless options[:test_app]
        rails_command "calagator:install:migrations"
        rails_command "db:migrate"
        rails_command "db:test:prepare"
      end
    end

    private

    def add_route
      inject_into_file "config/routes.rb", "\s\smount Calagator::Engine => '/'\n", after: "routes.draw do\n"
    end

    # PaperTrail needs Time and BigDecimal as supported YAML classes
    def add_yaml_config
      inject_into_file "config/application.rb",
        "\s\s\s\sconfig.active_record.yaml_column_permitted_classes = [ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, Time, BigDecimal]",
        after: /config.load_defaults.+\n/
    end

    def add_initializers
      initializer "01_calagator.rb", File.read(File.expand_path("templates/config/initializers/01_calagator.rb", __dir__))
      initializer "02_geokit.rb", File.read(File.expand_path("templates/config/initializers/02_geokit.rb", __dir__))
      initializer "03_recaptcha.rb", File.read(File.expand_path("templates/config/initializers/03_recaptcha.rb", __dir__))
      initializer "04_devise.rb", File.read(File.expand_path("templates/config/initializers/04_devise.rb", __dir__))
    end

    def add_javascripts
      create_file "app/assets/javascripts/application.js", "//= require calagator"
    end

    def add_stylesheets
      insert_into_file "app/assets/stylesheets/application.css", before: "*/" do
        <<-STR.strip_heredoc

          //= require calagator
        STR
      end
    end

    def add_assets
      run "cp #{File.expand_path("../../../app/assets/images/spinner.gif", __dir__)} app/assets/images/"
      run "cp #{File.expand_path("../../../app/assets/images/site-icon.png", __dir__)} app/assets/images/"
    end

    def add_devise_views
      FileUtils.cp_r(File.expand_path("./templates/app/views/devise/", __dir__), "app/views/")
    end

    def add_seeds
      append_file "db/seeds.rb", "Calagator::Engine.load_seed"
    end
  end
end
