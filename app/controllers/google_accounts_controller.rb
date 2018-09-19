class GoogleAccountsController<ApplicationController

  def generate_password()
      render json: {password: RandomPasswordGenerator.generate(12,:skip_symbols=>true)}
  end

  def password_generator()

  end

  def update
    @google_account = GoogleAccount.find(params[:id])
    response = if @google_account.update_attributes(google_account_params)
      {status: 200, updated_at: @google_account.updated_at.strftime("Updated on %m/%d/%Y at %I:%M %p")}
    else
      {status: 500}
    end
    render json: response, status: response[:status]
  end

  def google_account_params
    params.require(:google_account)
  end
end
