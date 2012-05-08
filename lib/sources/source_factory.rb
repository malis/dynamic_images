module DynamicImageSources
  class SourceFactory
    private_class_method :new

    private
    def self.inherited(subclass)
      @@factories ||= []
      @@factories << subclass
    end

    public
    def self.parse(source)
      raise Exception.new "not implemented in #{self}, but should be" unless self == SourceFactory
      source = source.class == Array ? source.map(&:to_s).map(&:downcase) : source.to_s.downcase.split(/\s+/)
      @@factories.each do |factory|
        obj = factory.parse source
        return obj if obj
      end
      nil
    end

    def set_source(context)
      raise Exception.new "not implemented in #{self.class}, but should be"
    end
  end
end

require File.dirname(__FILE__) + '/color_source.rb'
