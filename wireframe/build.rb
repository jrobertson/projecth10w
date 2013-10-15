#!/usr/bin/env ruby

# file: build.rb

require 'dynarex'
require 'hlt'


class String

  def to_html()
    Hlt.new(self.gsub(/^(?=[^\n])/,'  ').sub(/^\s{2}/,'')).to_html
  end

  def to_doc()  Rexle.new(self.to_html)  end
end

class Ph10w

  def initialize(file, options={})
    @opt = {style: true}.merge options
    @dynarex = Dynarex.new
    @dynarex.parse File.read file
  end

  def generate()

    keys = @dynarex.records.keys
    @template = keys.shift
    nav2 = keys.shift.sub(/^[^\n]+\n/,'')

    @pages = keys.inject({}) do |r, x| 
      label, val = x.split(/\n/,2)
      r.merge({label.strip.to_sym => val})
    end

    other = [:Hygiene, :'Outside catering', :Classes, :BSA]
    level0 = @pages.keys - other 

    # insert the nav2 code into 'other' pages
    generate_pages(other) do |doc|
      e = doc.element('//div[@id="nav2"]')
      e.add nav2.to_doc.root.element('ul')
    end

    generate_pages level0
  end

  private

  # generate the html for the 1st item.
  #
  def generate_pages(a)

    a.each do |name|

      doc = @template.to_doc
      doc2 = ("div {id: 'cols'}\n" + @pages[name]).to_doc
      yield(doc2) if block_given?

      e = doc.element('//div[@id="cols"]')
      e.insert_before doc2.root
      e.delete

      pg_name = name.to_s

      title = doc.root.element('head/title')
      title.text = title.text.sub('Home', pg_name)
      name = 'index' if name == :Home
      filename = "%s.html" % name.to_s.downcase.gsub(' ','-')

      if @opt[:style] == false then
        doc.root.xpath('//.[@style]').each {|e| e.attributes.delete :style}
      end

      puts 'saving ' + filename
      File.write filename, doc.xml 
    end
  end

end

if __FILE__ == $0 then

  Ph10w.new('pages.txt').generate

end
