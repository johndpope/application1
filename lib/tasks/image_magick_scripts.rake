namespace :imagemagick_scripts do
	#rake aspect_crop_set['/tmp/test.jpg',n]
  task :aspect_crop_set, [:input_file, :gravity] => :environment do |t, args|
		img_ext = File.extname args.input_file
		img_basename = File.basename(args.input_file).gsub(img_ext, '')
		img = Magick::Image.read(args.input_file).first

		crop_side_1 = 600
		crop_side_2 = 300

		crop_side_1 = img.columns/2 unless img.columns > 1024
		crop_side_2 = img.rows/2 unless img.rows > 768

		if(crop_side_1 < crop_side_2)
			tmp_side = crop_side_1
			crop_side_1 = crop_side_2
			crop_side_2 = tmp_side
		end

		output = File.join('/tmp', "#{img_basename}-aspect-crop-square#{img_ext}")
		ImagemagickScripts.aspect_crop(args.input_file, "#{crop_side_1}x#{crop_side_1}", args.gravity).write(output).destroy!
		puts output

		output = File.join('/tmp', "#{img_basename}-aspect-crop-horizontal#{img_ext}")
		ImagemagickScripts.aspect_crop(args.input_file, "#{crop_side_1}x#{crop_side_2}", args.gravity).write(output).destroy!
		puts output

		output = File.join('/tmp', "#{img_basename}-aspect-crop-vertical#{img_ext}")
		ImagemagickScripts.aspect_crop(args.input_file, "#{crop_side_2}x#{crop_side_1}", args.gravity).write(output).destroy!
		puts output
  end
end
