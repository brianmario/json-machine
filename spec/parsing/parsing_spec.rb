# encoding: UTF-8
require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "JsonMachine::Parser" do
  before(:each) do
    @parser = JsonMachine::Parser.new
  end
  
  it "should parse a string" do
    @parser.parse('"this is a string"').should === "this is a string"
  end
  
  it "should parse a string with an escaped string inside" do
    parse_str = "\"this is a string with \\\"and escaped string inside\\\"    and some padding    \""
    compare = "this is a string with \\\"and escaped string inside\\\"    and some padding    "
    out = @parser.parse(parse_str)
    out.should === compare
  end
  
  it "should parse an integer" do
    @parser.parse('123456').should === 123456
  end
  
  it "should parse a float" do
    @parser.parse('123456.789').should === 123456.789
  end
  
  it "should parse a number with an exponent" do
    @parser.parse('23456789012E66').should == 23456789012E66
    @parser.parse('1.234567890E+34').should == 1.234567890E+34
    @parser.parse('0.123456789e-12').should == 0.123456789e-12
  end
  
  it "should parse a simple hash" do
    @parser.parse('{"key":"value"}').should === {"key" => "value"}
  end
  
  it "should parse a simple array" do
    @parser.parse('["value", "value2"]').should === ["value", "value2"]
  end
  
  it "should parse a array with every type as a value" do
    pending
    @parser.parse('["value", false, true, null, 123456, 123456.789, {"key": "value"}, ["nested", "array"]]').should === ["value", false, true, nil, 123456, 123456.789, {"key" => "value"}, ["nested", "array"]]
  end
  
  it "should parse a boolean (true)" do
    @parser.parse('true').should === true
  end
  
  it "should parse a boolean (false)" do
    @parser.parse('false').should === false
  end
  
  it "should parse null" do
    @parser.parse('null').should == nil
  end
end