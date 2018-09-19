module Templates
  def self.table_name_prefix
    'templates_'
  end

  TRANSITION_TYPES = {
    simple_transition: 8,
    text_transition: 9,
    image_text_transition: 10,
		logo_transition: 16,
		transition: nil
  }

  VIDEO_CHUNK_TYPES = {
    introduction: 1,
    bridge_to_subject: 3,
    summary_points: 4,
    collage: 2,
    call_to_action: 5,
		phone_call_to_action: 15,
    ending: 6,
    likes_and_views: 11,
    social_networks: 12,
    credits: 7,
		subscription: 14
  }

  GENERAL_TYPES = {
    subject: 13
  }

  VIDEO_TYPES = TRANSITION_TYPES.merge(VIDEO_CHUNK_TYPES).merge(GENERAL_TYPES)
end
