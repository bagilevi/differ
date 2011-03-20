module Differ
  class Diff
    def initialize
      @raw = []
    end

    def same(*str)
      return if str.empty?
      if @raw.last.is_a? String
        @raw.last << sep
      elsif @raw.last.is_a? Change
        if @raw.last.change?
          @raw << sep
        else
          change = @raw.pop
          if change.insert? && @raw.last
            @raw.last << sep if change.insert.sub!(/^#{Regexp.quote(sep)}/, '')
          end
          if change.delete? && @raw.last
            @raw.last << sep if change.delete.sub!(/^#{Regexp.quote(sep)}/, '')
          end
          @raw << change

          @raw.last.insert << sep if @raw.last.insert?
          @raw.last.delete << sep if @raw.last.delete?
          @raw << ''
        end
      else
        @raw << ''
      end
      @raw.last << str.join(sep)
    end

    def delete(*str)
      return if str.empty?
      if @raw.last.is_a? Change
        change = @raw.pop
        if change.insert? && @raw.last
          @raw.last << sep if change.insert.sub!(/^#{Regexp.quote(sep)}/, '')
        end
        change.delete << sep if change.delete?
      else
        change = Change.new(:delete => @raw.empty? ? '' : sep)
      end

      @raw << change
      @raw.last.delete << str.join(sep)
    end

    def insert(*str)
      return if str.empty?
      if @raw.last.is_a? Change
        change = @raw.pop
        if change.delete? && @raw.last
          @raw.last << sep if change.delete.sub!(/^#{Regexp.quote(sep)}/, '')
        end
        change.insert << sep if change.insert?
      else
        change = Change.new(:insert => @raw.empty? ? '' : sep)
      end

      @raw << change
      @raw.last.insert << str.join(sep)
    end

    def ==(other)
      @raw == other.raw_array
    end

    def to_s
      @raw.join()
    end
    
    def insertions
      @raw.select{|r| r.is_a? Differ::Change and r.insert?}
    end

    def deletions
      @raw.select{|r| r.is_a? Differ::Change and r.delete?}
    end

    def changes
      @raw.select{|r| r.is_a? Differ::Change}
    end

    def changed?
      @raw.any?{|r| r.is_a? Differ::Change}
    end

    def pieces
      @raw
    end

    def merge!(other_diff)
      other_diff.pieces.each do |piece|
        self << piece
      end
    end

    def <<(piece)
      if @raw.empty? || !mergeable?(@raw.last, piece)
        @raw << piece
      else
        last_piece = @raw.last
        merge_pieces(last_piece, piece)
      end
    end

    def mergeable?(a, b)
      (a.is_a?(Change) && b.is_a?(Change)) || (a.is_a?(String) && b.is_a?(String))
    end

    def merge_pieces(a, b)
      if a.is_a?(Change) && b.is_a?(Change)
        if b.insert?
          a.insert << sep if a.insert?
          a.insert << b.insert
        end
        if b.delete?
          a.delete << sep if a.delete?
          a.delete << b.delete
        end
      else
        a << sep unless a.empty?
        a << b
      end
    end

    def unchanged_length
      @raw.reject{|r| r.is_a? Differ::Change}.map(&:length).inject(&:+)
    end

    def format_as(f)
      f = Differ.format_for(f)
      @raw.inject('') do |sum, part|
        part = case part
        when String then part
        when Change then f.format(part)
        end
        sum << part
      end
    end

    protected
    def raw_array
      @raw
    end

    private
    def sep
      "#{$;}"
    end
  end
end
