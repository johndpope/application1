require 'net/ftp'
require 'action_view'
require 'action_view/helpers'
include ActionView::Helpers::DateHelper

class RenderingMachine < ActiveRecord::Base
	validates_presence_of :ip, :user, :password, :order_nr, :vmware_server_id
	validates_uniqueness_of :ip
	validates_uniqueness_of :order_nr, scope: :vmware_server_id

	belongs_to :vmware_server, class_name: 'Vmware::Server'

	attr_accessor :ftp_broadcaster_dir,
		:ftp_broadcaster_aae_projects_dir,
		:ftp_watch_folder_dir,
		:ftp_watch_folder_output_dir,
		:ftp_ame_logs_dir,
		:ftp_ame_log_file_name,
		:info_file_name,
		:ftp_info_file_path

	after_initialize do
		@ftp_broadcaster_dir = '/broadcaster'
		@ftp_broadcaster_aae_projects_dir = "#{@ftp_broadcaster_dir}/aae_projects"
		@ftp_watch_folder_dir = "/#{ftp_broadcaster_dir}/watch_folders/720p"
		@ftp_watch_folder_output_dir = "#{@ftp_watch_folder_dir}/Output"
		@ftp_ame_logs_dir = "#{ftp_broadcaster_dir}/ame_logs"
		@ftp_ame_log_file_name = 'AMEEncodingLog.txt'
		@info_file_name = 'rendering_machine_info.yml'
		@ftp_info_file_path = File.join(@ftp_broadcaster_dir, @info_file_name)

		if self.new_record?
			self.user = 'ftp'
			self.rdp_user = 'render'
		end
	end

  def name_with_status
    "#{name} (#{is_active ? 'active' : 'inactive'})"
  end

	def ftp_connection
		ftp = Net::FTP.new
		ftp.connect(self.ip)
		ftp.passive = true
		ftp.login(self.user, self.password)
		return ftp
	end

	def today_video_sets
		BlendedVideo.distinct.
			joins(:blended_video_chunks).
			joins('INNER JOIN templates_dynamic_aae_projects on blended_video_chunks.templates_dynamic_aae_project_id = templates_dynamic_aae_projects.id').
			where('templates_dynamic_aae_projects.rendering_machine_id' => self.id).
			where("templates_dynamic_aae_projects.created_at::date = ?", Time.now.to_date).count
	end

	def total_video_sets
		BlendedVideo.distinct.
			joins(:blended_video_chunks).
			joins('INNER JOIN templates_dynamic_aae_projects on blended_video_chunks.templates_dynamic_aae_project_id = templates_dynamic_aae_projects.id').
			where('templates_dynamic_aae_projects.rendering_machine_id' => self.id).count
	end

	def today_video_chunks
		BlendedVideoChunk.
			joins(:dynamic_aae_project).
			where('templates_dynamic_aae_projects.rendering_machine_id' => self.id).
			where("blended_video_chunks.created_at::date = ?", Time.now.to_date).count
	end

	def total_video_chunks
		BlendedVideoChunk.
			joins(:dynamic_aae_project).
			where('templates_dynamic_aae_projects.rendering_machine_id' => self.id).count
	end

	def number_of_generating_dynamic_projects
		Delayed::Job.
			where(queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE).
			where("handler like ?","%rendering_machine_name: #{self.name}\n%").count
	end

	def time_of_last_created_project
		Templates::DynamicAaeProject.
			where(rendering_machine_id: self.id).
			order(created_at: :desc).first.try(:created_at)
	end

	def time_ago_of_last_created_project
		if from_time = time_of_last_created_project
			time_ago_in_words(Time.now - Time.zone.parse(from_time))
		end
	end

	def occupied_disk_space_percentage
		if(available_disk_space.to_i !=0 && total_disk_space.to_i !=0)
			100 - ((available_disk_space*100).to_f/total_disk_space.to_f).round(1)
		end
	end

	def name
		server_order_nr = (vmware_server.blank? || self.vmware_server.order_nr.blank?) ? '-' : self.vmware_server.order_nr
		vm_order_nr = self.order_nr.blank? ? '-' : self.order_nr

		"Server #{server_order_nr} | Container #{vm_order_nr}"
	end
end
