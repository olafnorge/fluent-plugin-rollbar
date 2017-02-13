require 'eventmachine'
require 'em-http-request'
require 'fluent/output'
require 'json'

module Fluent
    class RollbarOutput < BufferedOutput
        # First, register the plugin. NAME is the name of this plugin
        # and identifies the plugin in the configuration file.
        Fluent::Plugin.register_output('rollbar', self)

        # config_param defines a parameter. You can refer a parameter via @path instance variable
        # Without :default, a parameter is required.
        config_param :access_token, :string
        config_param :endpoint, :string, default: 'https://api.rollbar.com/api/1/item/'

        # This method is called before starting.
        # 'conf' is a Hash that includes configuration parameters.
        # If the configuration is invalid, raise Fluent::ConfigError.
        def configure(conf)
            super
            $log.info 'Rollbar Output initializing'
        end

        # This method is called when starting.
        # Open sockets or files here.
        def start
            super
        end

        # This method is called when shutting down.
        # Shutdown the thread and close sockets or files here.
        def shutdown
            super
            $log.info 'Rollbar Output shutting down'
        end

        # This method is called when an event reaches to Fluentd.
        # Convert the event to a raw string.
        def format(tag, time, record)
            # [tag, time, record].to_json + "\n"
            ## Alternatively, use msgpack to serialize the object.
            [tag, time, record].to_msgpack
        end

        # This method is called every flush interval. Write the buffer chunk
        # to files or databases here.
        # 'chunk' is a buffer chunk that includes multiple formatted
        # events. You can use 'data = chunk.read' to get all events and
        # 'chunk.open {|io| ... }' to get IO objects.
        #
        # NOTE! This method is called by internal thread, not Fluentd's main thread. So IO wait doesn't affect other plugins.
        # def write(chunk)
        #    data = chunk.read
        #    print data
        # end

        ## Optionally, you can use chunk.msgpack_each to deserialize objects.
        def write(chunk)
            chunk.msgpack_each do |(_tag, _time, record)|
                record = record['log'] if record.key? 'log'

                EventMachine.run do
                    record['access_token'] = @access_token
                    headers = { 'X-Rollbar-Access-Token' => @access_token }
                    req = EventMachine::HttpRequest.new(@endpoint).post(body: record.to_json, head: headers)

                    req.callback do
                        if req.response_header.status != 200
                            $log.warn "rollbar: Got unexpected status code from Rollbar.io api: #{req.response_header.status}"
                            $log.warn "rollbar: Response: #{req.response}"
                        end

                        EventMachine.stop
                    end

                    req.errback do
                        $log.warn "rollbar: Call to API failed, status code: #{req.response_header.status}"
                        $log.warn "rollbar: Error's response: #{req.response}"

                        EventMachine.stop
                    end
                end
            end
        rescue Exception => e
            $log.warn "rollbar: #{e}"
        end
    end
end
