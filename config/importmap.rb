# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "apexcharts", to: "https://cdn.jsdelivr.net/npm/apexcharts@3.36.0/dist/apexcharts.min.js"
pin "datatables.net", to: "https://cdn.datatables.net/1.11.5/js/jquery.dataTables.min.js"
pin "datatables.net-bs5", to: "https://cdn.datatables.net/1.11.5/js/dataTables.bootstrap5.min.js"
pin "datatables.net-buttons", to: "https://cdn.datatables.net/buttons/2.1.1/js/dataTables.buttons.min.js"
pin "datatables.net-buttons-bs5", to: "https://cdn.datatables.net/buttons/2.1.1/js/buttons.bootstrap5.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
