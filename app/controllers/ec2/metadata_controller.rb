module Ec2
  class MetadataController < ApplicationController
    def index
      @instance = Instance.new
      @metadata = Metadata.new
    end

    def show
      @instance = Instance.new
      @metadata = Metadata.new(path: params[:path])
    end
  end
end
