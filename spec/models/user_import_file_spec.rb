# -*- encoding: utf-8 -*-
require 'spec_helper'

describe UserImportFile do
  fixtures :all

  describe "when its mode is 'create'" do
    before(:each) do
      @file = UserImportFile.new :user_import => File.new("#{Rails.root.to_s}/../../examples/user_import_file_sample.tsv")
      @file.default_user_group = UserGroup.find(2)
      @file.default_library = Library.find(3)
      @file.user = users(:admin)
      @file.save
    end

    it "should be imported" do
      old_users_count = User.count
      old_import_results_count = UserImportResult.count
      @file.current_state.should eq 'pending'
      @file.import_start.should eq({:user_imported => 5, :user_found => 0, :failed => 0})
      User.order('id DESC')[1].username.should eq 'user005'
      User.order('id DESC')[2].username.should eq 'user003'
      User.count.should eq old_users_count + 5

      user002 = User.where(:username => 'user002').first
      user002.user_number.should eq '001002'
      user002.user_group.name.should eq 'faculty'
      user002.expired_at.to_i.should eq Time.zone.parse('2013-12-01').end_of_day.to_i
      user002.valid_password?('4NsxXPLy')
      user002.user_number.should eq '001002'
      user002.library.name.should eq 'hachioji'
      user002.locale.should eq 'en'

      user003 = User.where(:username => 'user003').first
      user003.note.should eq 'テストユーザ'
      user003.role.name.should eq 'Librarian'
      user003.user_number.should eq '001003'
      user003.library.name.should eq 'kamata'
      user003.locale.should eq 'ja'
      user003.checkout_icalendar_token.should eq 'secrettoken'
      user003.save_checkout_history.should be_truthy
      user003.save_search_history.should be_falsy
      user003.share_bookmarks.should be_falsy
      User.where(:username => 'user000').first.should be_nil
      UserImportResult.count.should eq old_import_results_count + 6

      user005 = User.where(username: 'user005').first
      user005.role.name.should eq 'User'
      user005.library.name.should eq 'hachioji'
      user005.locale.should eq 'en'
      user005.user_number.should eq '001005'
      user005.user_group.name.should eq 'faculty'

      user006 = User.where(username: 'user006').first
      user006.role.name.should eq 'User'
      user006.library.name.should eq 'hachioji'
      user006.locale.should eq 'en'
      user006.user_number.should be_nil
      user006.user_group.name.should eq UserGroup.find(2).name

      @file.user_import_fingerprint.should be_truthy
      @file.executed_at.should be_truthy
    end

    it "should not import users that have higher roles than current user's role" do
      old_users_count = User.count
      old_import_results_count = UserImportResult.count
      @file.user = User.where(username: 'librarian1').first
      @file.import_start.should eq({:user_imported => 4, :user_found => 0, :failed => 1})
      User.order('id DESC')[1].username.should eq 'user005'
      User.count.should eq old_users_count + 4
    end
  end

  describe "when its mode is 'update'" do
    it "should update users" do
      @file = UserImportFile.create :user_import => File.new("#{Rails.root.to_s}/../../examples/user_update_file.tsv")
      @file.modify
    end
  end

  describe "when its mode is 'destroy'" do
    before(:each) do
      @file = UserImportFile.new :user_import => File.new("#{Rails.root.to_s}/../../examples/user_import_file_sample.tsv")
      @file.user = users(:admin)
      @file.save
      @file.import_start
    end

    it "should remove users" do
      old_count = User.count
      @file = UserImportFile.create :user_import => File.new("#{Rails.root.to_s}/../../examples/user_delete_file.tsv")
      @file.remove
      User.count.should eq old_count - 3
    end
  end

  it "should import in background" do
    file = UserImportFile.new :user_import => File.new("#{Rails.root.to_s}/../../examples/user_import_file_sample.tsv")
    file.user = users(:admin)
    file.save
    UserImportFileQueue.perform(file.id).should be_truthy
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
#
