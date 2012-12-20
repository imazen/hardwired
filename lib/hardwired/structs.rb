=begin
  
rescue Copyright (c) 2009 William (B.J.) Snow Orvis

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=end



require 'ostruct'

module Hardwired

  #Like a hash, but retrival works even if the key has additional characters afterwars.
  #keys are bucketed by the prefix length. 
  #O(M log N), where M is the length of the longest prefix, and N is the number of prefixes sharing a length.
  class PrefixHash

    def buckets
      @a || []
    end 

    def [](key)
      return nil if @a.nil?
      #it would be better to reverse_each_with_index, but that doesn't exist
      result = nil
      @a.each_with_index do |v,i|
        next if v.nil?
        break if key.length < i -1 
        part = key[0..i]
        result = v[part]
        break if !result.nil?
      end 
      return result

    end
    def []=(name, value)
      @a ||= []
      @a[name.length-1]  ||= Hash.new
      @a[name.length-1][name] = value;
    end

  end 

  class CaseInsensitiveHash < Hash
    def [](key) super(key.to_s.downcase.to_sym) end
    def []=(name, value) super(name.to_s.downcase.to_sym,value) end
  end



class RecursiveOpenStruct < OpenStruct

  def initialize(hash=nil, args={})
    @recurse_over_arrays = args.fetch(:recurse_over_arrays,false)
    @case_insensitive = true
    
    @table = CaseInsensitiveHash.new
    if hash
      hash.each_pair do |k, v|
        k = k.to_sym
        @table[k] = v
        new_ostruct_member(k)
      end
    end
  end
  
  def [](key) @table[key] end

  def new_ostruct_member(tablename)

    name = tablename.to_s.downcase.gsub(" ","_").to_sym
    unless self.respond_to?(name)
      class << self; self; end.class_eval do
        define_method(name) do
          v = @table[tablename]
          if v.is_a?(Hash)
            RecursiveOpenStruct.new(v)
          elsif v.is_a?(Array) && @recurse_over_arrays
            v.map { |a| (a.is_a? Hash) ? RecursiveOpenStruct.new(a, :recurse_over_arrays => true) : a }
          else
            v
          end
        end
        define_method("#{name}=") { |x| modifiable[tablename] = x }
        define_method("#{name}_as_a_hash") { @table[tablename] }
      end
    end
    name
  end

  def debug_inspect(io = STDOUT, indent_level = 0, recursion_limit = 12)
    display_recursive_open_struct(io, @table, indent_level, recursion_limit)
  end

  def display_recursive_open_struct(io, ostrct_or_hash, indent_level, recursion_limit)

    if recursion_limit <= 0 then
      # protection against recursive structure (like in the tests)
      io.puts '  '*indent_level + '(recursion limit reached)'
    else
      #puts ostrct_or_hash.inspect
      if ostrct_or_hash.is_a?(RecursiveOpenStruct) then
        ostrct_or_hash = ostrct_or_hash.marshal_dump
      end

      # We'll display the key values like this :    key =  value
      # to align display, we look for the maximum key length of the data that will be displayed
      # (everything except hashes)
      data_indent = ostrct_or_hash \
        .reject { |k, v| v.is_a?(RecursiveOpenStruct) || v.is_a?(Hash) } \
          .max {|a,b| a[0].to_s.length <=> b[0].to_s.length}[0].to_s.length
      # puts "max length = #{data_indent}"

      ostrct_or_hash.each do |key, value|
        if (value.is_a?(RecursiveOpenStruct) || value.is_a?(Hash)) then
          io.puts '  '*indent_level + key.to_s + '.'
          display_recursive_open_struct(io, value, indent_level + 1, recursion_limit - 1)
        else
          io.puts '  '*indent_level + key.to_s + ' '*(data_indent - key.to_s.length) + ' = ' + value.inspect
        end
      end
    end

    true
  end

end

end