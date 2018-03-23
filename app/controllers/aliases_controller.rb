class AliasesController < ApplicationController
  def new
    @instance = Ec2::Instance.new
    @alias = @instance.alias
  end

  def create
    @instance = Ec2::Instance.new
    @alias = Alias.new(alias_params)
    respond_to do |format|
      if @alias.save
        format.html { redirect_to ec2_metadata_path }
      else
        format.html { render :new }
        format.js
      end
    end
  end

  private

  def alias_params
    params.require(:alias).permit(:instance_id, :value)
  end
end
