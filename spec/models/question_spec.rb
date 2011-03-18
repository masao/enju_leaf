# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Question do
  fixtures :questions

  it "should get refkyo search" do
    result = Question.search_porta('Yahoo', {:dpid => 'refkyo'})
    result.items.size.should > 0
    result.channel.totalResults.should be_true
  end

  it "test_should_get_crd_search" do
    result = Question.search_crd(:query_01 => 'Yahoo')
    result.should be_true
    result.total_entries.should > 0
  end

  it "should respond to last_updated_at" do
    questions(:question_00001).last_updated_at
  end
end