# frozen_string_literal: true

class NotionClient
  NOTION_API_URL = 'https://api.notion.com/v1/pages'

  def initialize(api_key, database_id)
    @api_key = api_key
    @database_id = database_id
  end

  def create_page(title, markdown_content)
    uri = URI.parse(NOTION_API_URL)
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request['Notion-Version'] = '2022-06-28'

    content_chunks = markdown_content.scan(/.{1,2000}/m)

    children_blocks = content_chunks.map do |chunk|
      {
        object: 'block',
        type: 'paragraph',
        paragraph: {
          rich_text: [
            {
              type: 'text',
              text: {
                content: chunk
              }
            }
          ]
        }
      }
    end

    request.body = {
      parent: { database_id: @database_id },
      properties: {
        title: {
          title: [
            {
              text: {
                content: title
              }
            }
          ]
        }
      },
      children: children_blocks
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end
end
