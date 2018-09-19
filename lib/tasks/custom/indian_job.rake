namespace :indian_job do
    desc "Import csv file with 3000 us gmails into table with google accounts"
    task step1_import_3000_us_gmails: :environment do
      IndianJob::step1_import_3000_us_gmails
    end

    desc "Import Spreadsheet with linked gmails into separate table"
    task step2_import_linked_spreadsheet: :environment do
      IndianJob::step2_import_linked_spreadsheet
    end

    desc "Import linked gmails"
      task step3_import_linked_gmails: :environment do
      IndianJob::step3_import_linked_gmails()
    end

    desc "Import csv with 53 gmails into table with google accounts"
    task step4_import_53_gmails: :environment do
      IndianJob::step4_import_53_gmails
    end

  	desc "Import 7000 US gmail accounts"
	  task step6_import_7000_us_gmails: :environment do
  	  IndianJob::step6_import_7000_us_gmails()
  	end

  	desc "Import csv file with 10 test gmails into table with google accounts"
  	task step5_import_10_test_gmails: :environment do
  		IndianJob::step5_import_10_test_gmails
  	end

    desc "Imports list of international gmail accounts into db"
    task step7_import_international_gmail_accounts: :environment do
      IndianJob::step7_import_international_gmail_accounts()
    end

    desc "Remove google accounts containing non ascii chars"
    task step8_remove_non_ascii_gmails: :environment do
      IndianJob::step8_remove_non_ascii_gmails()
    end

    desc "Imports corrected gmail accounts into db"
    task step9_import_repaired_inaccessible_gmails: :environment do
      IndianJob::step9_import_repaired_inaccessible_gmails()
    end

    desc "Fix 49 inaccessible gmail accounts"
    task step10_import_49_repaired_inaccessible_gmails: :environment do
      IndianJob::step10_import_49_repaired_inaccessible_gmails()
    end

    desc "Determine gmails statuses"
    task step11_determine_gmails_statuses: :environment do
      IndianJob::step11_determine_gmails_statuses
    end

    desc "Remove spaces from begin and end of google accounts cities"
    task step12_strip_gmails_localities: :environment do
      IndianJob::step12_strip_gmails_localities()
    end

    desc "Set locality_id to gmails"
    task set_locality_id_to_gmails: :environment do
      IndianJob::set_locality_id_to_gmails()
    end
end