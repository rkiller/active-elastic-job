module ActiveElasticJob
  class Railtie < Rails::Railtie
    puts "Statrting ActiveElasticJob"
    config.active_elastic_job = ActiveSupport::OrderedOptions.new
    config.active_elastic_job.process_jobs = ENV['PROCESS_ACTIVE_ELASTIC_JOBS'] == 'true'
    puts "Processing Jobs: " + config.active_elastic_job.process_jobs.to_s
    config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
    config.active_elastic_job.aws_region = ENV['AWS_REGION']
    puts "Setting Credentials"
    config.active_elastic_job.periodic_tasks_route = '/periodic_tasks'.freeze
    puts "Route: " + config.active_elastic_job.periodic_tasks_route.to_s

    initializer "active_elastic_job.insert_middleware" do |app|
      if app.config.active_elastic_job.secret_key_base.blank?
	      puts "Setting Key Secret"
        app.config.active_elastic_job.secret_key_base = app.secrets[:secret_key_base]
      end
puts "Checking for process jobs flag..."
      if app.config.active_elastic_job.process_jobs == true
	      puts "Jobs Process Flag was set!"
        if app.config.force_ssl
		puts "Force SSL"
          app.config.middleware.insert_before(ActionDispatch::SSL,ActiveElasticJob::Rack::SqsMessageConsumer)
        else
          app.config.middleware.use(ActiveElasticJob::Rack::SqsMessageConsumer)
        end
      end
    end
    puts "Finishing Active Elastic Job Setup"
  end
end
