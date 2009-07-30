# encoding: UTF-8
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe "JsonMachine::Parser" do
  before(:each) do
    @parser = JsonMachine::Parser.new
  end
  
  it "should parse a string" do
    @parser.parse('"this is a string"').should == "this is a string"
  end
  
  it "should parse a number" do
    @parser.parse('123456').should == 123456
  end
  
  it "should parse a simple hash" do
    pending
    @parser.parse('{"key":"value"}').should == {"key" => "value"}
  end
  
  it "should parse a simple array" do
    pending
    @parser.parse('["value", "value2"]').should == ["value", "value2"]
  end
  
  it "should parse a boolean (true)" do
    @parser.parse('true').should == true
  end
  
  it "should parse a boolean (false)" do
    @parser.parse('false').should == false
  end
  
  it "should parse null" do
    @parser.parse('null').should == nil
  end
end