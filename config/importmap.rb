# config/importmap.rb

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.20
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.20
pin_all_from "app/javascript/controllers", under: "controllers"


pin_all_from "app/javascript/api", under: "api"
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.1.100
