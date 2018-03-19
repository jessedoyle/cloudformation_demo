module Ec2
  class MetadataController < ApplicationController
    def index
      @metadata = Metadata.new
    end

    def show
      @metadata = Metadata.new(path: params[:path])
    end
  end
end
