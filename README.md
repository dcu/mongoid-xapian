= mongoid-xapian

Xapian for mongoid

== Usage

Include MongoidXapian in your model and define what fields need to be
indexed.

    class YourModel
      include Mongoid::Document
      include MongoidXapian

      fti :title, :body
    end

now you have to run `MongoidXapian.index!` to index the changes into
xapian.
A rake task called `xapian:index` is also provided.

once you configure your model and index it you can search it using:

    YourModel.search(query)



== Contributing to mongoid-xapian
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2012 David A. Cuadrado. See LICENSE.txt for
further details.

