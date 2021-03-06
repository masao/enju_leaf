class UserImportFile < ActiveRecord::Base
  attr_accessible :user_import, :edit_mode, :user_encoding, :mode,
    :default_user_group_id, :default_library_id
  include Statesman::Adapters::ActiveRecordModel
  include ImportFile
  default_scope {order('user_import_files.id DESC')}
  scope :not_imported, -> {in_state(:pending)}
  scope :stucked, -> {in_state(:pending).where('created_at < ? AND state = ?', 1.hour.ago)}

  if Setting.uploaded_file.storage == :s3
    has_attached_file :user_import, :storage => :s3,
      :s3_credentials => "#{Setting.amazon}",
      :s3_permissions => :private
  else
    has_attached_file :user_import,
      :path => ":rails_root/private/system/:class/:attachment/:id_partition/:style/:filename"
  end
  validates_attachment_content_type :user_import, :content_type => [
    'text/csv',
    'text/plain',
    'text/tab-separated-values',
    'application/octet-stream',
    'application/vnd.ms-excel'
  ]
  validates_attachment_presence :user_import
  belongs_to :user, :validate => true
  belongs_to :default_user_group, class_name: 'UserGroup'
  belongs_to :default_library, class_name: 'Library'
  has_many :user_import_results

  has_many :user_import_file_transitions

  enju_import_file_model
  attr_accessor :mode

  def state_machine
    @state_machine ||= UserImportFileStateMachine.new(self, transition_class: UserImportFileTransition)
  end

  delegate :can_transition_to?, :transition_to!, :transition_to, :current_state,
    to: :state_machine

  def import
    transition_to!(:started)
    num = {:user_imported => 0, :user_found => 0, :failed => 0}
    rows = open_import_file(create_import_temp_file)
    row_num = 1

    field = rows.first
    if [field['username']].reject{|f| f.to_s.strip == ""}.empty?
      raise "username column is not found"
    end

    rows.each do |row|
      row_num += 1
      next if row['dummy'].to_s.strip.present?
      import_result = UserImportResult.create!(
        :user_import_file_id => id, :body => row.fields.join("\t")
      )

      username = row['username']
      new_user = User.where(:username => username).first
      if new_user
        import_result.user = new_user
        import_result.save
        num[:user_found] += 1
      else
        new_user = User.new
        new_user.role = Role.where(:name => row['role']).first
        if new_user.role
          unless user.has_role?(new_user.role.name)
            num[:failed] += 1
            next
          end
        else
          new_user.role = Role.find(2) # User
        end
        new_user.operator = user
        new_user.username = username
        new_user.assign_attributes(set_user_params(new_user, row), as: :admin)

        if new_user.save
          num[:user_imported] += 1
          import_result.user = new_user
          import_result.save!
        else
          num[:failed] += 1
        end
      end
    end

    rows.close
    transition_to!(:completed)
    Sunspot.commit
    num
  rescue => e
    self.error_message = "line #{row_num}: #{e.message}"
    transition_to!(:failed)
    raise e
  end

  def modify
    transition_to!(:started)
    num = {:user_updated => 0, :user_not_found => 0, :failed => 0}
    rows = open_import_file(create_import_temp_file)
    row_num = 1

    field = rows.first
    if [field['username']].reject{|f| f.to_s.strip == ""}.empty?
      raise "username column is not found"
    end

    rows.each do |row|
      row_num += 1
      next if row['dummy'].to_s.strip.present?
      import_result = UserImportResult.create!(
        :user_import_file_id => id, :body => row.fields.join("\t")
      )

      username = row['username']
      new_user = User.where(:username => username).first
      if new_user
        new_user.assign_attributes(set_user_params(new_user, row), as: :admin)
        if new_user.save
          num[:user_updated] += 1
          import_result.user = new_user
          import_result.save!
        else
          num[:failed] += 1
        end
      else
        num[:user_not_found] += 1
      end
    end

    rows.close
    transition_to!(:completed)
    Sunspot.commit
    num
  rescue => e
    self.error_message = "line #{row_num}: #{e.message}"
    transition_to!(:failed)
    raise e
  end

  def remove
    transition_to!(:started)
    row_num = 1
    rows = open_import_file(create_import_temp_file)

    field = rows.first
    if [field['username']].reject{|field| field.to_s.strip == ""}.empty?
      raise "username column is not found"
    end

    rows.each do |row|
      row_num += 1
      username = row['username'].to_s.strip
      user = User.where(:username => username).first
      user.destroy if user
    end
    transition_to!(:completed)
  rescue => e
    self.error_message = "line #{row_num}: #{e.message}"
    transition_to!(:failed)
    raise e
  end

  private
  def self.transition_class
    UserImportFileTransition
  end

  def create_import_temp_file
    tempfile = Tempfile.new(self.class.name.underscore)
    if Setting.uploaded_file.storage == :s3
      uploaded_file_path = user_import.expiring_url(10)
    else
      uploaded_file_path = user_import.path
    end
    open(uploaded_file_path){|f|
      f.each{|line|
        tempfile.puts(convert_encoding(line))
      }
    }
    tempfile.close
    tempfile
  end

  def open_import_file(tempfile)
    file = CSV.open(tempfile.path, 'r:utf-8', :col_sep => "\t")
    header = file.first
    rows = CSV.open(tempfile.path, 'r:utf-8', :headers => header, :col_sep => "\t")
    UserImportResult.create!(:user_import_file_id => self.id, :body => header.join("\t"))
    tempfile.close(true)
    file.close
    rows
  end

  def self.import
    UserImportFile.not_imported.each do |file|
      file.import_start
    end
  rescue
    Rails.logger.info "#{Time.zone.now} importing resources failed!"
  end

  private
  def set_user_params(new_user, row)
    params = {}
    params[:email] = row['email'] if row['email'].present?
    user_group = UserGroup.where(name: row['user_group']).first
    unless user_group
      user_group = default_user_group
    end
    params[:user_group_id] = user_group.id if user_group
    params[:user_number] = row['user_number']
    if row['expired_at'].present?
      params[:expired_at] = Time.zone.parse(row['expired_at']).end_of_day
    end
    if row['keyword_list'].present?
      params[:keyword_list] = row['keyword_list'].split('//').join('\n')
    end
    params[:note] = row['note']

    if I18n.available_locales.include?(row['locale'].to_s.to_sym)
      params[:locale] = row['locale']
    end

    library = Library.where(name: row['library'].to_s.strip).first
    unless library
      library = default_library || Library.web
    end
    params[:library_id] = library.id if library

    if row['password'].present?
      params[:password] = row['password']
    else
      params[:password] = Devise.friendly_token[0..7]
    end

    if defined?(EnjuCirculation)
      params[:checkout_icalendar_token] = row['checkout_icalendar_token'] if row['checkout_icalendar_token'].present?
      params[:save_checkout_history] = row['save_checkout_history'] if row['save_checkout_history'].present?
    end
    if defined?(EnjuSearchLog)
      params[:save_search_history] = row['save_search_history'] if row['save_search_history'].present?
    end
    if defined?(EnjuBookmark)
      params[:share_bookmarks] = row['share_bookmarks'] if row['share_bookmarks'].present?
    end
    params
  end
end

# == Schema Information
#
# Table name: user_import_files
#
#  id                       :integer          not null, primary key
#  user_id                  :integer
#  note                     :text
#  executed_at              :datetime
#  user_import_file_name    :string(255)
#  user_import_content_type :string(255)
#  user_import_file_size    :string(255)
#  user_import_updated_at   :datetime
#  user_import_fingerprint  :string(255)
#  edit_mode                :string(255)
#  error_message            :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_encoding            :string(255)
#  default_library_id       :integer
#  default_user_group_id    :integer
#
