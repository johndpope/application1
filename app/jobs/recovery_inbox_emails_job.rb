RecoveryInboxEmailsJob = Struct.new(:email_account_id) do
	def perform
		email_account = EmailAccount.find(email_account_id)
		EmailService.retrieve_recovery_inbox_emails(email_account)
	end

	def max_attempts
		3
	end

	def max_run_time
		3600 #seconds
	end

	def reschedule_at(current_time, attempts)
		current_time + 20.minutes
	end
end
