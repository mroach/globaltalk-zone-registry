ActiveSupport.on_load(:good_job_application_controller) do
  include Authentication

  before_action do
    unless Current.user.admin?
      head(:not_found)
    end
  end
end

Rails.application.configure do
  config.good_job = {
    # for now we're only having single instances, so they should run cron and jobs
    enable_cron: true,
    execution_mode: :async,
    cron: {
      spreadsheet_import: {
        cron: "every 6 hours",
        class: "SheetIngestor::UpdateJob"
      },
      generate_map: {
        cron: "every hour",
        class: "MapGenerator::GenerateImageJob"
      }
    }
  }
end
