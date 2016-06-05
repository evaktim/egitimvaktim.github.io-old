module Jekyll
  class BaseArchivePage < Page
    def initialize(site, posts, pager=nil)
      if @layout.nil?
        @layout = "%s_archive" % self.class.to_s.split('::').last.to_s.sub('ArchivePage', '').downcase
      end
      @site = site
      @posts = posts
      @dir = ''
      @url = @baseurl  # URL without pagination

      @name = 'index.html'
      @base = "#{@url}#{@name}"

      halt_on_layout_error unless layout_available?

      super @site, @base, @dir, @name
    end

    def to_liquid
      data
    end

    def read_yaml(base, name)
      # Don't need to do anything but satisfy Jekyll's contract
    end

    def layout_available?
      @site.layouts.include? @layout
    end

    def data
      {
        "layout" => @layout,
        "posts" => @posts,
        "url" => @url,
        "baseurl" => @baseurl,
        "pager" => @pager,
      }
    end

    def halt_on_layout_error
      $stderr.puts self.layout_err_msg
      exit(-1)
    end

    # Add pagination data to this page.
    def add_pager(pager)
      @pager = pager
      if @pager.page != 1
        # Fix URL and file name if necessary.
        @url = @baseurl + "page/#{pager.page}/"
        @name = "#{@url}index.html"
      end
    end
  end

  module ArchiveGenerator
    def default_bucket
      {:posts => [], :subs => {}}
    end

    def initialize(config = {})
      super(config)
      @bucket = {}
    end

    def generate(site)
      @site = site
      @bucket = {}  # Empty bucket on each page generation.
      site.posts.dup.each { |post| add_to_bucket(post) }
      process
    end

    # Generate one or more pages from a list of posts with a given
    # page class, if pagination is enabled.
    def paginate(site, all_posts, pageclass, feedclass, pageargs=[])
      if site.config['paginate'].nil?
        site.pages << pageclass.new(site, all_posts, *pageargs)
      else
        pages = Paginate::Pager.calculate_pages(all_posts, site.config['paginate'].to_i)
        all_posts.each_slice(@site.config['paginate']).with_index do |slice, i|
          pager = Paginate::Pager.new(site, i + 1, all_posts, pages)

          newpage = pageclass.new(site, slice, *pageargs)
          newpage.add_pager(pager)

          @site.pages << newpage
        end
      end

      if !feedclass.nil?  # Generate RSS feed too.
        site.pages << feedclass.new(site, all_posts, *pageargs)
      end
    end

  end
end
