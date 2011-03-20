require 'differ/change'
require 'differ/diff'
require 'differ/format/ascii'
require 'differ/format/color'
require 'differ/format/html'

module Differ
  class << self

    def diff(target, source, separators = ["\n"])
      d = Diff.new
      return sub_diff(d, target, source, separators)
    end

    def sub_diff(d, target, source, separators)
      separators = (separators.is_a?(Array) ? separators : [separators])
      additional_separators = separators.dup
      separator = additional_separators.shift
      old_sep, $; = $;, separator

      target = target.split(separator)
      source = source.split(separator)

      $; = '' if separator.is_a? Regexp

      advance(d, target, source, additional_separators) until source.empty? || target.empty?
      d.insert(*target) || d.delete(*source)
      return d
    ensure
      $; = old_sep
    end

    def diff_by_char(to, from)
      diff(to, from, '')
    end

    def diff_by_word(to, from)
      diff(to, from, /([\b ])/)
    end

    def diff_by_line(to, from)
      diff(to, from, "\n")
    end

    def diff_combined(to, from)
      diff(to, from, ["\n", /([\b ])/, ''])
    end

    def format=(f)
      @format = format_for(f)
    end

    def format
      return @format || Format::Ascii
    end

    def format_for(f)
      case f
      when Module then f
      when :ascii then Format::Ascii
      when :color then Format::Color
      when :html  then Format::HTML
      when nil    then nil
      else raise "Unknown format type #{f.inspect}"
      end
    end

  private
    def advance(d, target, source, additional_separators = [])
      del, add = source.shift, target.shift

      prioritize_insert = target.length > source.length
      insert = (target.index(del) unless del =~ /^\s+$/)
      delete = (source.index(add) unless add =~ /^\s+$/)

      if del == add
        d.same(add)
      else
        if insert && prioritize_insert
          change(d, :insert, target.unshift(add), insert)
        elsif delete
          change(d, :delete, source.unshift(del), delete)
        elsif insert && !prioritize_insert
          change(d, :insert, target.unshift(add), insert)
        else
          sub_d = if additional_separators.any?
            sub_d = Diff.new
            sub_diff(sub_d, add, del, additional_separators)
          end
          if sub_d && sub_d.unchanged_length > del.length * 0.5
            d.merge! sub_d
          else
            d.insert(add) && d.delete(del)
          end
        end
      end
    end

    def change(d, method, array, index)
      d.send(method, *array.slice!(0..index))
      d.same(array.shift)
    end

    def next_matching_indexes(target, source)
    end
  end
end



