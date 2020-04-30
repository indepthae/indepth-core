module ReminderHelper
  # changes from simple format
  # 1. no paragraph tag
  # 2. preserve space
  # 3. linkify the output
  # 4. Do not format if text is already html
  def simple_format_without_p(text, html_options={})
       start_tag = tag('pre', html_options, true)
       text = text.to_s.dup
       plain_text=sanitize(text, :tags=>[:a])
       if plain_text == text
         text.gsub!(/\r\n?/, "\n")
         text.gsub!(/(\n)/, '<br/>')
        #  text.gsub!(" ","&nbsp;")
         text.insert 0, start_tag
         text << "</pre>"
         auto_link( text, :html => { :target => '_blank' })
      else
        text.insert 0, start_tag
        text << "</pre>"
      end
  end
end
