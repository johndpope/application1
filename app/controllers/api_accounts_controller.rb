class ApiAccountsController < ApplicationController
  before_action :set_api_account, only: [:show, :edit, :update, :destroy]
  API_ACCOUNTS_DEFAULT_LIMIT = 25

  def index
    params[:limit] = API_ACCOUNTS_DEFAULT_LIMIT unless params[:limit].present?

    if params[:filter].present?
      params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
      params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
    else
      params[:filter] = { order: 'updated_at', order_type: 'desc' }
    end

    order_by = params[:filter][:order]

    @api_accounts = ApiAccount.all
    .by_id(params[:id])
    .by_names(params[:name])
    .by_website(params[:website])
    .by_username(params[:username])
    .page(params[:page]).per(params[:limit])
    .order(order_by + ' ' + params[:filter][:order_type])
  end

  def new
    @api_account = ApiAccount.new
  end

  def show
  end

  def create
    @api_account = ApiAccount.new(api_account_params)
    if @api_account.save
      redirect_to api_accounts_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @api_account.update(api_account_params)
      redirect_to api_accounts_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @api_account.destroy
    redirect_to api_accounts_path
  end

  private

    def set_api_account
      @api_account = ApiAccount.find(params[:id])
    end

    def api_account_params
      params.require(:api_account).permit(:website, :username, :password, :api_key , :balance , :name, :registration_email, :description, :currency )
    end
end
