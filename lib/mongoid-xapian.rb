require 'bundler/setup'

$:.unshift File.expand_path(File.dirname(__FILE__))

require 'mongoid'
require 'xapian-fu'

require 'mongoid-xapian/trail'
require 'mongoid-xapian/indexer'
require 'mongoid-xapian/tasks'

module MongoidXapian
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :xapian_options, :xapian_fields
    end

    field :xapian_id, :type => Integer

    after_create do |doc|
      MongoidXapian::Trail.create(:action => :create,
                                  :doc_type => doc.class.to_s,
                                  :doc_id => doc.id)
    end

    after_update do |doc|
      MongoidXapian::Trail.create(:action => :update,
                                  :doc_type => doc.class.to_s,
                                  :doc_id => doc.id)
    end

    after_destroy do |doc|
      MongoidXapian::Trail.create(:action => :destroy,
                                  :doc_type => doc.class.to_s,
                                  :doc_id => doc.xapian_id)
    end
  end

  def xapian_indexer
    MongoidXapian::Indexer.new(self)
  end

  def to_xapian
    fields = {:_id => self._id}
    self.class.xapian_fields.each do |field|
      fields[field] = self.send(field)
    end

    fields
  end

  # Usage: MongoidXapian.index_all!
  # short cut for MongoidXapian::Trail.index_all!
  def self.index!
    MongoidXapian::Trail.index_all!
  end

  module ClassMethods
    def fti(*args)
      @xapian_options = args.extract_options!
      @xapian_fields = args
    end

    def xapian_db(language = "en")
      @xapian_databases ||= {}

      @xapian_databases[language] ||= XapianFu::XapianDb.new({
        :dir => self.xapian_db_path(language),
        :create => true,
        :store => @xapian_fields
      })
    end

    def xapian_db_path(language = "en")
      "#{Bundler.root}/db/#{self.to_s.underscore}.#{language}.db"
    end

    def search(pattern, language = "en")
      xapian_db(language).search(pattern)
    end
  end
end
