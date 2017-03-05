module ActiveElasticJob
  class Railtie < Rails::Railtie
    puts "Statrting ActiveElasticJob"
    config.active_elastic_job = ActiveSupport::OrderedOptions.new
    config.active_elastic_job.process_jobs = ENV['PROCESS_ACTIVE_ELASTIC_JOBS'] == 'true'
    puts "Processing Jobs: " + config.active_elastic_job.process_jobs
    config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
    puts "Setting Credentials"
    config.active_elastic_job.periodic_tasks_route = '/periodic_tasks'.freeze
    puts "Route: " + config.active_elastic_job.periodic_tasks_route

    initializer "active_elastic_job.insert_middleware" do |app|
      if app.config.active_elastic_job.secret_key_base.blank?
        app.config.active_elastic_job.secret_key_base = app.secrets[:secret_key_base]
      end

      if app.config.active_elastic_job.process_jobs == true
        if app.config.force_ssl
          app.config.middleware.insert_before(ActionDispatch::SSL,ActiveElasticJob::Rack::SqsMessageConsumer)
        else
          app.config.middleware.use(ActiveElasticJob::Rack::SqsMessageConsumer)
        end
      end
    end
  end
end
