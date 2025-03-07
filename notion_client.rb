# frozen_string_literal: true

require 'redcarpet'
require 'nokogiri'

class NotionClient
  NOTION_API_URL = 'https://api.notion.com/v1/pages'

  def initialize(api_key, database_id)
    @api_key = api_key
    @database_id = database_id
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
  end

  def create_page(title, markdown_content)
    uri = URI.parse(NOTION_API_URL)
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request['Notion-Version'] = '2022-06-28'

    html_content = @markdown.render(markdown_content)


    children_blocks = html_to_notion_blocks(html_content)

    # content_chunks = markdown_content.scan(/.{1,2000}/m)

    # children_blocks = content_chunks.map do |chunk|
    #   {
    #     object: 'block',
    #     type: 'paragraph',
    #     paragraph: {
    #       rich_text: [
    #         {
    #           type: 'text',
    #           text: {
    #             content: chunk
    #           }
    #         }
    #       ]
    #     }
    #   }
    # end

    request.body = {
      parent: { database_id: @database_id },
      properties: {
        title: { title: [{ text: { content: title } }] }
      },
      children: children_blocks
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  private

  def html_to_notion_blocks(html)
    doc = Nokogiri::HTML::fragment(html)
    blocks = []

    doc.children.each do |node|
      case node.name
      when 'p'
        blocks.concat(chunk_text(node.text, 2000, 'paragraph'))
      when 'h1', 'h2', 'h3'
        heading_level = case node.name
                        when 'h1' then 'heading_1'
                        when 'h2' then 'heading_2'
                        when 'h3' then 'heading_3'
                        end
        blocks << {
          object: 'block',
          type: heading_level,
          heading_level => { rich_text: [{ type: 'text', text: { content: node.text.strip } }] }
        } if heading_level
      when 'ul'
        node.css('li').each do |li|
          blocks << {
            object: 'block',
            type: 'bulleted_list_item',
            bulleted_list_item: {
              rich_text: [{ type: 'text', text: { content: li.text.strip } }]
            }
          }
        end
      when 'ol'
        node.css('li').each_with_index do |li, index|
          blocks << {
            object: 'block',
            type: 'numbered_list_item',
            numbered_list_item: {
              rich_text: [{ type: 'text', text: { content: li.text.strip } }]
            }
          }
        end
      when 'blockquote'
        blocks << {
          object: 'block',
          type: 'quote',
          quote: {
            rich_text: [{ type: 'text', text: { content: node.text.strip } }]
          }
        }
      when 'code'
        # Code block handling
        code_content = node.text.strip
        blocks << {
          object: 'block',
          type: 'code',
          code: {
            rich_text: [{ type: 'text', text: { content: code_content } }],
            language: 'javascript'  # assuming code is in JavaScript, you can adjust as needed
          }
        }
      when 'span'
        if node['class'] == 'math'
          blocks << {
            object: 'block',
            type: 'equation',
            equation: {
              expression: node.text.strip
            }
          }
        end
      else
        puts "Skipping unsupported node: #{node.name}"
      end
    end

    blocks
  end

  def chunk_text(text, max_length, type)
    text.scan(/.{1,#{max_length}}/m).map do |chunk|
      {
        object: 'block',
        type: type,
        paragraph: {
          rich_text: [{ type: 'text', text: { content: chunk.strip } }]
        }
      }
    end
  end

  def convert_markdown_to_notion_blocks(markdown)
    renderer = Redcarpet::Render::HTML.new
    markdown_converter = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
    html = markdown_converter.render(markdown)

    html_to_notion_blocks(html)
  end
end
