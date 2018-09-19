ActiveAdmin.register Artifacts::HumanPhoto do
    menu parent: 'Artifacts', label: 'Human Photos'
    config.per_page = 100

    filter :person_initials
    filter :source_id, label: 'Image Source ID'
    filter :person_source_id, label: 'Person Source ID'
    filter :type, collection: %w(Artifacts::VkPhoto), as: :select
    filter :person_gender, collection: Artifacts::HumanPhoto::GENDERS, as: :select
    filter :person_age, collection: (18..40), as: :select

    index do
        paginated_collection(collection, download_links: false)
        selectable_column
        column :id
        column 'Photo' do |photo|
            link_to photo.source_url, target: '_BLANK' do
                image_tag photo.file.url(:google_avatar)
            end unless photo.file.blank?
        end
        column 'Person Profile page' do |photo|
            link_to(photo.person_source_url, photo.person_source_url, target: '_BLANK') unless photo.person_source_url.blank?
        end
        column :person_initials
        column 'Person Age' do |photo|
            Time.now.year - photo.person_birth_year unless photo.person_birth_year.blank?
        end
        column :person_gender
        column 'Type' do |photo|
            photo.class.name
        end
        actions
    end
end
