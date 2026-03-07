module ApplicationHelper
  def render_markdown(str)
    return nil if str.blank?

    renderer = Redcarpet::Render::HTML.new(filter_html: true)
    options = {
      autolink: true,
      fenced_code_blocks: true,
      highlight: true,
      no_intra_emphasis: true,
      strikethrough: true,
      tables: true,
      underline: true
    }

    tag.div(class: "markdown") do
      Redcarpet::Markdown.new(renderer, options).render(str).html_safe
    end
  end
end
