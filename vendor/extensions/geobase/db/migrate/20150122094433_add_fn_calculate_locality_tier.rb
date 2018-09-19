class AddFnCalculateLocalityTier < ActiveRecord::Migration
  def change
  	execute <<-SQL
  		CREATE OR REPLACE FUNCTION calculate_locality_tier(_locality_id bigint)
		  RETURNS integer AS
		$BODY$
		DECLARE
			population int;
		BEGIN
			SELECT l.population INTO population FROM geobase_localities AS l WHERE id=_locality_id;

			IF(NOT FOUND)THEN
				RETURN 0;
			END IF;

			IF(population>500000) THEN
				RETURN 1;
			ELSIF(population BETWEEN 100000 AND 500000) THEN
				RETURN 2;
			ELSIF(population BETWEEN 50000 AND 99999) THEN
				RETURN 3;
			ELSIF(population BETWEEN 25000 AND 49999) THEN
				RETURN 4;
			ELSIF(population BETWEEN 10000 AND 24999) THEN
				RETURN 5;
			ELSIF(population BETWEEN 5000 AND 9999) THEN
				RETURN 6;
			ELSIF(population BETWEEN 2500 AND 4999) THEN
				RETURN 7;
			ELSE
				RETURN 8;
			END IF;
		END
		$BODY$
		  LANGUAGE plpgsql IMMUTABLE
		  COST 100;
  	SQL
  end
end
