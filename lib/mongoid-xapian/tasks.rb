require 'rake'
require 'fileutils'

namespace :xapian do
  desc "Index all pending documents"
  task :index do
    FileUtils.mkpath("#{Bundler.root}/db")
    MongoidXapian::Trail.index_all!
  end

  desc "Reindex all documents in the given model. pass MODEL=ModelName to this task"
  task :reindex do
    model = ENV['MODEL'].constantize
    model.all.each do |doc|
      MongoidXapian::Trail.create!(:action => :update,
                                   :doc_id => doc.id,
                                   :doc_type => doc.class.to_s)
    end
  end
end
