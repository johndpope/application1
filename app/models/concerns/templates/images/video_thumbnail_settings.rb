module Templates::Images::VideoThumbnailSettings
	THUMBNAILS = {
		Thumbnail1: {images: {client: [:subject_image], location: [:background_image]}, texts: {location: :text0, client: :text1, bridge_to_sub_text: :text2, video_subject: :text3}},
		Thumbnail2: {images: {client: [:subject_image], location: [:background_image]}, texts: {location: :text0, client: :text1, video_subject: :text2}},
		Thumbnail3: {images: {client: [:subject_image1, :subject_image3], location: [:subject_image2, :background_image]}, texts: {location: :text0, video_subject: :text1}},
		Thumbnail4: {images: {client: [:subject_image1, :subject_image2, :subject_image3, :subject_image4], location: [:background_image]}, texts: {location: :text0, video_subject: :text1}},
		Thumbnail5: {images: {client: [:subject_image2, :subject_image3, :logo], location: [:subject_image1]}, texts: {location: :text0, video_subject: :text1}},
		Thumbnail6: {images: {client: [:subject_image2, :subject_image3], location: [:subject_image1, :subject_image4]}, texts: {location: :text0, client: :text1, video_subject: :text2}},
		Thumbnail7: {images: {client: [:subject_image], location: [:background_image]}, texts: {location: :text0, client: :text1, video_subject: :text2}},
		Thumbnail8: {images: {client: [:background_image], location: [:subject_image]}, texts: {location: :text0, client: :text1, video_subject: :text2}},
		Thumbnail9: {images: {client: [:subject_image], location: [:logo]}, texts: {location: :text0, video_subject: :text1}},
		Thumbnail10: {images: {client: [:subject_image2], location: [:subject_image1, :background_image]}, texts: {location: :text0, client: :text1, bridge_to_sub_text: :text2, video_subject: :text3}},
		Thumbnail11: {images: {client: [:subject_image, :background_image2], location: [:background_image1]}, texts: {location: :text0, client: :text1, video_subject: :text2}}
		# TODO: finish with icon based templates
	}
end
