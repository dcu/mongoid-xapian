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
      needs_indexing = false
      # see if at least one changed field is indexable
      doc.changes.each do |key, value|
        if doc.class.xapian_fields.include?(key)
          needs_indexing = true
          break
        end
      end

      if needs_indexing
        MongoidXapian::Trail.create(:action => :update,
                                    :doc_type => doc.class.to_s,
                                    :doc_id => doc.id)
      end
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
      # make sure id is not in the list
      args.delete(:id)

      # index mongodb' id
      args << :_id
 
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

    def search_db(language = "en")
      XapianFu::XapianDb.new({
        :dir => self.xapian_db_path(language),
        :create => false,
        :store => @xapian_fields
      })
    end

    def xapian_db_path(language = "en")
      "#{Bundler.root}/xapian/#{self.to_s.underscore}.#{language}.db"
    end

    def search(pattern, opts = {})
      language = opts.delete(:language) || 'en'
      ids = search_db(language).search(pattern, opts).map do |result|
        result.values[:_id]
      end

      self.where(:_id.in => ids)
    end
  end
end
