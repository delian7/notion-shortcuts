# frozen_string_literal: true

require_relative './spec_helper'
require_relative '../notion_client'

RSpec.describe NotionClient do
  let(:api_key) { 'test_api_key' }
  let(:database_id) { 'test_database_id' }
  let(:client) { NotionClient.new(api_key, database_id) }

  describe '#text_to_notion_blocks' do
    it 'converts headings correctly' do
      text = "# Heading 1\n## Heading 2\n### Heading 3"
      blocks = client.send(:text_to_notion_blocks, text)

      expect(blocks).to eq([
                             {
                               object: 'block',
                               type: 'heading_1',
                               heading_1: { rich_text: [{ type: 'text', text: { content: 'Heading 1' } }] }
                             },
                             {
                               object: 'block',
                               type: 'heading_2',
                               heading_2: { rich_text: [{ type: 'text', text: { content: 'Heading 2' } }] }
                             },
                             {
                               object: 'block',
                               type: 'heading_3',
                               heading_3: { rich_text: [{ type: 'text', text: { content: 'Heading 3' } }] }
                             }
                           ])
    end

    it 'converts bulleted list items correctly' do
      text = "- Item 1\n- Item 2"
      blocks = client.send(:text_to_notion_blocks, text)

      expect(blocks).to eq([
                             {
                               object: 'block',
                               type: 'bulleted_list_item',
                               bulleted_list_item: {
                                 rich_text: [{ type: 'text', text: { content: 'Item 1' } }]
                               }
                             },
                             {
                               object: 'block',
                               type: 'bulleted_list_item',
                               bulleted_list_item: {
                                 rich_text: [{ type: 'text', text: { content: 'Item 2' } }]
                               }
                             }
                           ])
    end

    it 'converts numbered list items correctly' do
      text = "1. Item 1\n2. Item 2"
      blocks = client.send(:text_to_notion_blocks, text)

      expect(blocks).to eq([
                             {
                               object: 'block',
                               type: 'numbered_list_item',
                               numbered_list_item: {
                                 rich_text: [{ type: 'text', text: { content: 'Item 1' } }]
                               }
                             },
                             {
                               object: 'block',
                               type: 'numbered_list_item',
                               numbered_list_item: {
                                 rich_text: [{ type: 'text', text: { content: 'Item 2' } }]
                               }
                             }
                           ])
    end

    it 'converts quotes correctly' do
      text = '> Quote'
      blocks = client.send(:text_to_notion_blocks, text)

      expect(blocks).to eq([
                             {
                               object: 'block',
                               type: 'quote',
                               quote: {
                                 rich_text: [{ type: 'text', text: { content: 'Quote' } }]
                               }
                             }
                           ])
    end

    it 'converts code blocks correctly' do
      text = "```\ncode line 1\ncode line 2\n```"
      blocks = client.send(:text_to_notion_blocks, text)

      expect(blocks).to eq([
                             {
                               object: 'block',
                               type: 'code',
                               code: {
                                 rich_text: [{ type: 'text', text: { content: "code line 1\ncode line 2" } }],
                                 language: 'javascript' # assuming code is in JavaScript, you can adjust as needed
                               }
                             }
                           ])
    end

    it 'converts paragraphs correctly' do
      text = 'This is a paragraph.'
      blocks = client.send(:text_to_notion_blocks, text)

      expect(blocks).to eq([
                             {
                               object: 'block',
                               type: 'paragraph',
                               paragraph: {
                                 rich_text: [{ type: 'text', text: { content: 'This is a paragraph.' } }]
                               }
                             }
                           ])
    end
  end
end
