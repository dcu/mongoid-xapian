require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "MongoidXapian" do
  after(:all) do
    BlogPost.destroy_all
    MongoidXapian.index!
    MongoidXapian::Trail.destroy_all
  end

  describe "Indexing documents" do
    it "should index the document" do
      blogpost = BlogPost.create(:title => "this is the title", :body => "this is body")
      MongoidXapian.index!
      BlogPost.search("the title").size.should >= 1
    end

    it "should work well concurrently" do
      10.times do
        Thread.start do
          blogpost = BlogPost.create!(:title => "this is the title", :body => "this is body")
        end
      end
      
      # wait until all docs are created
      while BlogPost.count < 10
        sleep 0.1
      end
      MongoidXapian.index!
    end
  end

  describe "Updating documents" do
    before do
      @blogpost = BlogPost.create(:title => "this is the title", :body => "this is body")
      MongoidXapian.index!
      @blogpost.reload
    end

    it "should update the index" do
      rand_string = rand(100000)
      @blogpost.title = "new title #{rand_string}"
      @blogpost.save
      MongoidXapian.index!

      results = BlogPost.search(rand_string)
      results.size.should >= 1
    end
  end

  describe "Destroying documents" do
    before do
      @blogpost = BlogPost.create(:title => "an unique title", :body => "this is body")
      MongoidXapian.index!
      @blogpost.reload
    end

    it "should delete the record from xapian" do
      BlogPost.search("unique").count.should == 1
      @blogpost.destroy
      MongoidXapian.index!

      BlogPost.search("unique").count.should == 0
    end
  end
end
