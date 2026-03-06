module ApplicationHelper
  def render_markdown(str)
    return nil if str.blank?

    tag.div(class: "markdown") do
      Redcarpet::Markdown
        .new(Redcarpet::Render::HTML, autolink: true, tables: true)
        .render(str)
        .html_safe
    end
  end
end
