module Ec2
  class Metadata
    METADATA_HOST = 'http://169.254.169.254/'.freeze
    DEFAULT_VERSION = '2016-09-02'.freeze

    attr_accessor :version, :path

    def initialize(opts = {})
      self.version = opts.fetch(:version) { DEFAULT_VERSION }
      self.path = opts.fetch(:path) { '' }
    end

    def data
      @data ||= begin
        response = RestClient::Request.execute(
          method: 'GET',
          url: uri,
          read_timeout: 5,
          open_timeout: 1,
          headers: {
            'Accept': 'text/plain'
          }
        )
        { error: nil, values: values_from(response.body) }
      end
    rescue RestClient::Exception, SystemCallError => e
      { error: e.message, values: [] }
    end

    def uri
      URI.join(METADATA_HOST, "#{version}/meta-data/#{path}").to_s
    end

    private

    def values_from(body)
      body.split("\n").map { |p| { text: p, path: File.join(path, p, '/') } }
    end
  end
end
