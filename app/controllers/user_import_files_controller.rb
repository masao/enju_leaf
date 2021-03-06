class UserImportFilesController < ApplicationController
  load_and_authorize_resource

  # GET /user_import_files
  # GET /user_import_files.json
  def index
    @user_import_files = UserImportFile.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @user_import_files }
    end
  end

  # GET /user_import_files/1
  # GET /user_import_files/1.json
  def show
    if @user_import_file.user_import.path
      unless Setting.uploaded_file.storage == :s3
        file = @user_import_file.user_import.path
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user_import_file }
      format.download {
        if Setting.uploaded_file.storage == :s3
          redirect_to @user_import_file.user_import.expiring_url(10)
        else
          send_file file, :filename => @user_import_file.user_import_file_name, :type => 'application/octet-stream'
        end
      }
    end
  end

  # GET /user_import_files/new
  # GET /user_import_files/new.json
  def new
    @user_import_file = UserImportFile.new
    @user_import_file.default_user_group = current_user.user_group
    @user_import_file.default_library = current_user.library
    prepare_options

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user_import_file }
    end
  end

  # GET /user_import_files/1/edit
  def edit
  end

  # POST /user_import_files
  # POST /user_import_files.json
  def create
    @user_import_file = UserImportFile.new(params[:user_import_file])
    @user_import_file.user = current_user

    respond_to do |format|
      if @user_import_file.save
        if @user_import_file.mode == 'import'
          Resque.enqueue(UserImportFileQueue, @user_import_file.id)
        end
        format.html { redirect_to @user_import_file, :notice => t('controller.successfully_created', :model => t('activerecord.models.user_import_file')) }
        format.json { render :json => @user_import_file, :status => :created, :location => @user_import_file }
      else
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @user_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_import_files/1
  # PUT /user_import_files/1.json
  def update
    respond_to do |format|
      if @user_import_file.update_attributes(params[:user_import_file])
        if @user_import_file.mode == 'import'
          Resque.enqueue(UserImportFileQueue, @user_import_file.id)
        end
        format.html { redirect_to @user_import_file, :notice => t('controller.successfully_updated', :model => t('activerecord.models.user_import_file')) }
        format.json { head :no_content }
      else
	prepare_options
        format.html { render :action => "edit" }
        format.json { render :json => @user_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /user_import_files/1
  # DELETE /user_import_files/1.json
  def destroy
    @user_import_file.destroy

    respond_to do |format|
      format.html { redirect_to(user_import_files_url) }
      format.json { head :no_content }
    end
  end

  private
  def prepare_options
    @user_groups = UserGroup.all
    @libraries = Library.all
  end
end
