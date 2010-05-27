excel_document(xml) do
  xml.Worksheet 'ss:Name' => '<%= plural_name.humanize %>' do
    xml.Table do
      # Header
      xml.Row do
          xml.Cell { xml.Data 'Attribute1', 'ss:Type' => 'String' }
          xml.Cell { xml.Data 'Attribute2', 'ss:Type' => 'String' }
      end

      # Rows
      unless @<%= plural_name %>.blank?
        for <%= singular_name %> in @<%= plural_name %>
          xml.Row do
            xml.Cell { xml.Data <%= singular_name %>.id, 'ss:Type' => 'Number' }
            xml.Cell { xml.Data <%= singular_name %>.id, 'ss:Type' => 'Number' }
          end
        end
      end

    end
  end
end