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
require 'recursive_open_struct'
require 'set'

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

  class NormalizingDeepDup
    def initialize(key_transform:, recurse_over_arrays: true)
      @key_transform = key_transform
      @recurse_over_arrays = recurse_over_arrays
    end
  
    def call(obj)
      deep_dup(obj)
    end
  
    private
  
    def deep_dup(obj, visited=Set.new)
      if obj.is_a?(Hash)
        obj.each_with_object({}) do |(key, value), h|
          h[@key_transform.call(key)] = value_or_deep_dup(value, visited)
        end
      elsif obj.is_a?(Array) && @recurse_over_arrays
        obj.each_with_object([]) do |value, arr|
          value = value.is_a?(RecursiveOpenStruct) ? value.to_h : value
          arr << value_or_deep_dup(value, visited)
        end
      else
        obj
      end
    end
  
    def value_or_deep_dup(value, visited)
      obj_id = value.object_id
      visited.include?(obj_id) ? value : deep_dup(value, visited << obj_id)
    end
  end

  class NormalizingRecursiveOpenStruct < RecursiveOpenStruct
    def initialize(hash={}, options={})
      hash ||= {}

      transform = ->(k) { k.to_s.downcase.gsub(" ","_").to_sym}
      
      normalizer = NormalizingDeepDup.new(key_transform: transform)
      super(normalizer.call(hash),     {
        mutate_input_hash: false,
        recurse_over_arrays: true,
        preserve_original_keys: false
      })
    
    end
  end
end