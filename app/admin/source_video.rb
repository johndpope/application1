require 'action_view'
require 'utils'
include ActionView::Helpers::NumberHelper

ActiveAdmin.register SourceVideo do    
  menu parent: 'Source Videos'

  filter :id
  filter :video_file_name
  filter :case_type_name, as: :string, label: 'Case Type Name'
  
  form :html=>{:enctype => 'multipart/form-data'} do |f|
    f.inputs "Details" do       
      f.input :video_script_id, as: :select, collection: VideoScript.where("title IS NOT NULL AND TITLE != ''").order(:title)
      if(f.object.video.present?)
        f.form_buffers.last << content_tag(:li) do
          content_tag(:label,'Current video') +
          content_tag(:div, link_to(source_video.video_file_name,source_video.video.url)) 
        end
        f.input :video, :as=>:file, :label=>'Upload new video'
      else
        f.input :video, :as=>:file, :label=>'Current video'
      end
      
      #TODO refactor code
      if(f.object.thumbnail.present?)        
        f.form_buffers.last << content_tag(:li) do
          content_tag(:label, 'Current thumbnail') +
          content_tag(:div, 
            content_tag(:div,f.template.image_tag(f.object.thumbnail.url(source_video.thumbnail.path), class: 'thumbnail-middle')) +
            content_tag(:div, 
              link_to('Remove',"/source_videos/#{source_video.id}/thumbnail/remove"), 
              :class=>'remove-thumbnail-wrapper'),
            :class=>'inline-hints')
        end
      else
        f.input :thumbnail, :as=>:file, :label=>'Current thumbnail'  
      end
      
      f.input :custom_title, :as=>:string
      f.input :custom_description
      f.input :language, :input_html=>{:class=>'middle'}, :as=>:select, collection: Language.order(:name), :selected=>Language.find(:first,:conditions=>{:code=>'en'}).id
      f.input :video_type, :input_html=>{:class=>'middle'}, :as=>:select
      f.input :creative_type, :input_html=>{:class=>'middle'}, :as=>:select
      f.input :jurisdiction, :input_html=>{:class=>'middle'}, :as=>:select
      f.input :target_audience, :input_html=>{:class=>'middle'}, :as=>:select
      f.input :case_type, :as=>:select, collection: CaseType.order(:name)
      f.input :has_music
      f.input :has_narration            
      f.input :youtube_video_category, :as=>:select, collection: YoutubeVideoCategory.order(:name), :selected=>YoutubeVideoCategory.find(:first,:conditions=>{:youtube_category_id=>22}).id
    end
    f.actions
  end
  
  index do
    selectable_column
    column :id    
    column 'Video File' do |source_video|
      link_to(Utils.shortify_file_name(source_video.video_file_name), source_video.video.url, {:title=>source_video.video_file_name})
    end
    column :video_file_size do |source_video|
      number_to_human_size(source_video.video_file_size)
    end
    column 'Thumb' do |source_video|
      image_tag(source_video.thumbnail.url,:class=>'thumbnail-mini') if(source_video.thumbnail.present?)
    end    
    column :video_type
    column :custom_title do |source_video|
      Utils::shortify(source_video.custom_title,120)
    end
    column :custom_description do |source_video|
      Utils::shortify(source_video.custom_description, 120)
    end    
    column :case_type

    actions 
  end
  
  show do
    attributes_table do
      row :id
      row :video_script_id
      row 'Video File' do |source_video|
        link_to(source_video.video_file_name, source_video.video.url)
      end      
      row :video_file_size do |source_video|             
        number_to_human_size(source_video.video_file_size)
      end
      row :video_updated_at                  
      row :custom_title
      row :custom_description
      row :language
      row :video_type
      row :creative_type
      row :jurisdiction
      row :target_audience
      row :case_type
      row :has_music
      row :has_narration            
      row :youtube_video_category
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
  
  controller do
    def permitted_params
      params.permit(source_video: [:video, 
        :thumbnail,
        :has_music, 
        :has_narration, 
        :language_id, 
        :creative_type, 
        :jurisdiction, 
        :target_audience, 
        :case_type_id, 
        :video_type, 
        :custom_title,
        :custom_description,
        :category_id,
        :video_script_id])
    end
  end
end
