class HostMachineController < ApplicationController
	HOST_MACHINE_LIMIT = 25

  def index
  	@host_machines = HostMachine.page(params[:page]).per(HOST_MACHINE_LIMIT).order(:url)
  end

  def show
  	@host_machine = HostMachine.find(params[:id])
    @api_applications = ApiApplication.where(host_machine_id: @host_machine.id).order(:app_item_type)
  end
end
