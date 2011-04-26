# Preprocessor helpers
# 
# This file has a collection of methods that are meant to be used in the
# preprocess-block in the Nanoc Rules file.
# 
# @author Arjan van der Gaag


# Generate a sitemap.xml file using Nanoc's own xml_sitemap helper method by
# dynamically adding a new item.
# 
# Make items that should not appear in the sitemap hidden. This by default
# works on all image files and typical assets, as well as error pages and
# htaccess. The is_hidden attribute is only explicitly set if it is absent,
# allowing per-file overriding.
# 
# @todo extract hidden file types into configuration file?
def create_sitemap
  @items.each do |item|
    if %w{png gif jpg jpeg css xml js txt}.include?(item[:extension]) ||
       item.identifier =~ /404|500|htaccess/
      item[:is_hidden] = true unless item.attributes.has_key?(:is_hidden)
    end
  end
  @items << Nanoc3::Item.new( 
    "<%= xml_sitemap %>",
    { :extension => 'xml' },
    '/sitemap/'
  )
end

# Use special settings from the site configuration to generate the files
# necessary for various webmaster tools authentications, such as the services
# from Google, Yahoo and Bing.
# 
# This loops through all the items in the `webmaster_tools` setting, using
# its properties to generate a new item.
# 
# See config.yaml for more documentation on the input format.
def create_webmaster_tools_authentications
  @site.config[:webmaster_tools].each do |file|
    next if file[:identifier].nil?
    content    = file.delete(:content)
    identifier = file.delete(:identifier)
    file.merge({ :is_hidden => true })
    @items << Nanoc3::Item.new(
      content,
      file,
      identifier
    )
  end
end

# Generate a robots.txt file in the root of the site by dynamically creating
# a new item.
# 
# This will either output a default robots.txt file, that disallows all
# assets except images, and points to the sitemap file.
# 
# You can override the contents of the output of this method using the site
# configuration, specifying Allow and Disallow directives. See the config.yaml
# file for more information on the expected input format.
def create_robots_txt
  if @site.config[:robots]
    content = if @site.config[:robots][:default]
      "User-agent: *\nDisallow: /assets\nAllow: /assets/images\nSitemap: /sitemap.xml"
    else
      [
        'User-Agent: *',
        @site.config[:robots][:disallow].map { |l| "Disallow: #{l}" },
        (@site.config[:robots][:allow] || []).map { |l| "Allow: #{l}" },
        "Sitemap: #{@site.config[:robots][:sitemap]}"
      ].flatten.compact.join("\n")
    end
    @items << Nanoc3::Item.new(
      content,
      { :extension => 'txt', :is_hidden => true },
      '/robots/'
    )
  end
end