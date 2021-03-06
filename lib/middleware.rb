require 'time'

module Pakyow
  module Assets
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if Pakyow::Config.assets.compile_on_request
          path = Pakyow::Assets.compiled_asset_path_for_request_path(env['PATH_INFO'])
        else
          path = File.join(Pakyow::Config.assets.compiled_asset_path, env['PATH_INFO'])
        end

        if path =~ /\.(.*)$/ && File.file?(path)
          catch :halt do
            headers = {
              'Content-Type' => Rack::Mime.mime_type(File.extname(path))
            }

            if Pakyow::Config.assets.cache && Pakyow::Assets.fingerprinted?(File.extname(path))
              mtime = File.mtime(path)
              headers['Age'] = (Time.now - mtime).to_i
              headers['Cache-Control'] = 'public, max-age=31536000'
              headers['Vary'] = 'Accept-Encoding'
              headers['Last-Modified'] = mtime.httpdate
            end

            [200, headers, File.open(path)]
          end
        else
          @app.call(env)
        end
      end
    end
  end
end
