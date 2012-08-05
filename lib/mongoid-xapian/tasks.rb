require 'rake'
require 'fileutils'

namespace :xapian do
  desc "Index all pending documents"
  task :index do
    puts "Indexing #{MongoidXapian::Trail.count} changes..."
    MongoidXapian::Trail.index_all!
  end

  desc "Reindex all documents in the given model"
  task :reindex do
    MongoidXapian.indexable_models.each do |mod|
      model_class = mod.constantize rescue nil
      if model_class
        puts ">> Indexing #{model_class}..."

        model_class.all.each do |doc|
          MongoidXapian::Trail.create!(:action => :update,
                                       :doc_id => doc.id,
                                       :doc_type => doc.class.to_s)
          MongoidXapian::Trail.index_all!
        end
      end
    end
  end
end
