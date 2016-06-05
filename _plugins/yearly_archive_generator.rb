require 'enumerator'

module Jekyll
  class YearlyArchivePage < BaseArchivePage
    attr_accessor :posts

    def layout_err_msg
      "
Hold your horses!  yearly_archive_generator plugin, here.

You've enabled me but haven't added a yearly_archive layout.
At least put an empty file there or I'm not going to run.

Missing file:
  %s/%s.html
" % ["_layouts", @layout]
    end

    def initialize(site, posts, year)
      @year = year
      @baseurl = "/%04d/" % [@year]
      super site, posts
    end

    def data
      Utils.deep_merge_hashes(super, {
        "year" => @year,
        "title" => @year.to_s,
      })
    end
  end

  class YearlyArchiveGenerator < Generator
    include ArchiveGenerator

    def add_to_bucket(post)
      @bucket[post.date.year] ||= default_bucket
      @bucket[post.date.year][:posts] << post
    end

    def process
      @bucket.each_pair do |year, data|
        posts = data[:posts]
        posts.sort! { |a,b| b.date <=> a.date }
        paginate(@site, posts, YearlyArchivePage, nil, [year])
      end
    end
  end

  # Calculate list of years and expose it to the templates
  class YearListGenerator < Generator
    def generate(site)
      site.config['years'] = site.posts.map {|p| p.date.year}.uniq.sort.reverse
    end
  end
end
