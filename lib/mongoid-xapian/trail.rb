module MongoidXapian
  class Trail
    include Mongoid::Document
    include Mongoid::Timestamps

    field :action, :type => String
    field :doc_id, :type => String
    field :doc_type, :type => String
    field :language, :type => String, :default => 'en'

    def index!
      self.send(:"#{action}_document")
      self.delete
    end

    def self.index_all!
      FileUtils.mkpath("#{Bundler.root}/xapian")
      while self.count != 0
        # get the documents in group of 100 so the cursor doesn't expire.
        self.order_by(:created_at.asc).limit(100).each do |trail|
          begin
            trail.index!
          rescue Exception => e
            puts "[mongoid-xapit] Something went wrong while indexing document #{trail.doc_type} #{trail.doc_id}: #{e.to_s} (#{e.class})"
            puts "#{e.backtrace[0,10].join("\n\t")}"
            trail.delete
          end
        end
      end
    end    

    def indexable
      @indexable ||= indexable_class.where(:_id => self.doc_id).first
    end

    def indexable_class
      self.doc_type.constantize
    end

    protected
    def with_xapian_database(&block)
      return if indexable_class.nil?

      xapian_db = indexable_class.xapian_db(self.language)
      block.call(xapian_db)
      xapian_db.flush
    end

    def create_document
      with_xapian_database do |db|
        xapian_doc = db.add_doc(indexable.to_xapian)
        indexable.set(:xapian_id, xapian_doc.id)
        indexable.xapian_id = xapian_doc.id
      end
    end

    def update_document
      with_xapian_database do |db|
        if indexable.present?
          if indexable.xapian_id.to_i > 0
            xapian_doc = XapianFu::XapianDoc.new(indexable.to_xapian.merge(:id => indexable.xapian_id), :xapian_db => db)
            xapian_doc.save
          else
            xapian_doc = db.add_doc(indexable.to_xapian)
            indexable.set(:xapian_id, xapian_doc.id)
            indexable.xapian_id = xapian_doc.id
          end
        end
      end
    end

    def destroy_document
      with_xapian_database do |db|
        if self.doc_id.to_i > 0
          db.documents.delete(self.doc_id)
        end
      end
    end
  end
end

