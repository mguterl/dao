if defined?(Rails)

  module Dao
  ## support unloadable
  #
    def Api.before_remove_const
      unload!
    end

  ##
  #
    class Engine < Rails::Engine
      GEM_DIR = File.expand_path(__FILE__ + '/../../../')
      ROOT_DIR = File.join(GEM_DIR, 'lib/dao/rails')

      ### ref: https://gist.github.com/af7e572c2dc973add221

      paths.path = ROOT_DIR

      config.autoload_paths += %w( app/models app )

      ### config.autoload_paths << APP_DIR
      ### $LOAD_PATH.push(File.join(Rails.root.to_s, 'app'))

    # drop the dao parameter parser in there...
    #
      #initializer "dao.middleware" do |app|
        #app.middleware.use Dao::Middleware::ParamsParser
      #end

    # yes yes, this should probably be somewhere else...
    #
      config.after_initialize do

        ActionController::Base.module_eval do

          before_filter do |controller|
          # set the dao controller
          #
            Dao.current_controller = controller

          # pre-parse any obvious dao params
          #
            controller.instance_eval do
              Dao.normalize_parameters(params)
            end
          end

        # you will likely want to override this!
        #
          def current_api
            @api ||= ( 
              api = Api.new
              %w( real_user effective_user current_user ).each do |attr|
                getter, setter = "#{ attr }", "#{ attr }="
                api.send(setter, send(getter)) if(respond_to?(getter) and api.respond_to?(setter))
              end
              api
            )
          end
          helper_method(:current_api)
          alias_method(:api, :current_api)
          helper_method(:api)

        # setup sane rescuing from dao errors with crap statuses
        #
        #   raise(Dao::Error::Result.new(result))
        #
          rescue_from(Dao::Error::Result) do |error|
            result = error.result
            basename = "#{ result.status.code }.html"
            error_page = File.join(Rails.root, 'public', basename)

            if test(?e, error_page)
              file = File.expand_path(error_page)
              status = result.status.code
              render(:file => file, :status => status, :layout => false)
            else
              text = result.status.to_s
              status = result.status.code
              render(:text => text, :status => status, :layout => false)
            end
          end
        end

      end

    end
  end
end
