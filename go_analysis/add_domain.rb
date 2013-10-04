#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-10-03.
#  Copyright (c). All rights reserved.
#
require 'json'
string = File.open(ARGV[0], "r").read

def find_id string
  string =~ /id:\s(.*)/
  id = $1
  string =~ /namespace:\s(.*)/
  name = $1
  if id =~ /^GO/
    return [id, name]
  else 
    return nil
  end
end

a = string.split(/\n\n/)
File.open("term_mapping.json", 'w').write(a.collect{ |e| find_id e }.compact.to_json )


