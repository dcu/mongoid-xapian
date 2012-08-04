module MongoidXapian
  module Indexer
    def self.add(doc)
      on_db(doc) do
        xapian_doc = documents.add(doc.to_xapian)
        doc.set(:xapian_id, xapian_doc.id)
      end
    end

    def self.update(doc)
      if doc.xapian_id
        on_db(doc) do
          xapian_doc = XapianFu::XapianDoc.new(doc.to_xapian.merge(:id => doc.xapian_id), :xapian_db => self)
          xapian_doc.save
        end
      else
        add(doc)
      end
    end

    def self.remove(doc)
      if doc.xapian_id
        on_db(doc) do
          documents.delete(doc.xapian_id)
        end
      end
    end

    private
    def self.on_db(doc, &block)
      10.times do
        begin
          doc.class.xapian_db.instance_exec(&block)
          break
        rescue IOError
        end
      end

      Thread.start do
        ok = false
        10.times do
          begin
            doc.class.xapian_db.flush
            ok = true
            break
          rescue IOError
          end
          sleep 0.1
        end

        puts "CANNOT UNLOCK DB" if !ok
      end
    end
  end
end
