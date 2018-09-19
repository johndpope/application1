module ImageFilters
	ROOT_DIR = File.join('/tmp','imagemagick','filters')

	def self.list
		res = []
		res << %w(black_white lense_flare vintage).map{|f|"ImageFilters::HipsterFilters::#{f.camelize}".constantize}
		res << %w(Gotham Nashville Lomo Toaster Kelvin).map{|f|"ImageFilters::InstagramFilters::#{f}".constantize}
		res << %w(NewYork LosAngeles).map{|f|"ImageFilters::FwFilters::Accentedges::#{f}".constantize}
		res << %w(Chicago Houston Philadelphia Phoenix SanAntonio SanDiego).map{|f|"ImageFilters::FwFilters::Bevelborder::#{f}".constantize}
		res << %w(Austin Dallas Indianapolis).map{|f|"ImageFilters::FwFilters::Bordereffects::#{f}".constantize}
		res << %w(Columbus Jacksonville SanFrancisco SanJose).map{|f|"ImageFilters::FwFilters::Bordergrid::#{f}".constantize}
		res << %w(FortWorth Charlotte).map{|f|"ImageFilters::FwFilters::Camerablur::#{f}".constantize}
		res << %w(Detroit ElPaso).map{|f|"ImageFilters::FwFilters::Cartoon::#{f}".constantize}
		res << %w(Memphis).map{|f|"ImageFilters::FwFilters::Clip::#{f}".constantize}
		res << %w(Baltimore Boston Denver NashvilleDavidson Seattle Washington).map{|f|"ImageFilters::FwFilters::Coloration::#{f}".constantize}
		res << %w(Louisville).map{|f|"ImageFilters::FwFilters::Colorcells::#{f}".constantize}
		res << %w(Albuquerque Fresno LasVegas Milwaukee Oklahoma Portland).map{|f|"ImageFilters::FwFilters::Crosshatch::#{f}".constantize}
		res << %w(Kansas LongBeach Mesa Sacramento Tucson).map{|f|"ImageFilters::FwFilters::Crossprocess::#{f}".constantize}
		res << %w(ColoradoSprings Miami).map{|f|"ImageFilters::FwFilters::Lichtenstein::#{f}".constantize}
		res << %w(Oakland).map{|f|"ImageFilters::FwFilters::Shapecluster::#{f}".constantize}
		res << %w(Cleveland Minneapolis Tulsa).map{|f|"ImageFilters::FwFilters::Thermography::#{f}".constantize}
		res << %w(Wichita Arlington).map{|f|"ImageFilters::FwFilters::Sketch::#{f}".constantize}
		res << %w(Bakersfield NewOrleans Tampa).map{|f|"ImageFilters::FwFilters::Sketchetch::#{f}".constantize}
		res << ImageFilters::FwFilters::Vintage1
		res << ImageFilters::FwFilters::Vignette2
		res.flatten
	end
end
