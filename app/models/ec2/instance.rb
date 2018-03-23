module Ec2
  class Instance
    def id
      @id ||= metadata.data[:values]&.first&.fetch(:text)
    end

    def alias
      @alias ||= Alias.find_or_initialize_by(instance_id: id)
    end

    private

    def metadata
      @metadata ||= Metadata.new(path: '/instance-id/')
    end
  end
end
