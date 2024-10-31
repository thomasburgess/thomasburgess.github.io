module Jekyll
  class DetailsTag < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @summary = markup.strip
    end

    def render(context)
      content = super
      <<-HTML
<details markdown="1">
<summary><i>#{@summary}</i><br/>&nbsp;<br/></summary>

#{content}

</details>
      HTML
    end
  end
end

Liquid::Template.register_tag('details', Jekyll::DetailsTag)
