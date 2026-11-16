#!/usr/bin/env ruby
# frozen_string_literal: true

# Creates a new post as a draft: content/YYYY/MM/DD/<slug>/index.md
#
# Usage:
#   ./scripts/new_post.rb "Post title"
#   ./scripts/new_post.rb "Post title" --tags programacao,ferramentas
#   ./scripts/new_post.rb "Post title" --slug another-slug
#
# The slug comes from the title with accents removed ("Ação" -> "acao").
# Posts start with `draft: true`, so nothing goes live until you remove it.

require 'optparse'
require 'yaml'

CONTENT_DIR = 'content'
TAXONOMY_PATH = 'data/tag_taxonomy.yml'

def slugify(text)
  text.unicode_normalize(:nfkd)
      .gsub(/\p{Mn}/, '')           # drop accents
      .downcase
      .gsub(/[^a-z0-9]+/, '-')      # anything else becomes a dash
      .gsub(/\A-+|-+\z/, '')
end

def pt_tags
  YAML.safe_load_file(TAXONOMY_PATH).fetch('tags').values.map { |t| t.fetch('pt') }.sort
rescue Errno::ENOENT
  []
end

def yaml_string(text)
  text.to_s.to_json # JSON strings are valid YAML double-quoted strings
end

options = { tags: [], slug: nil }
parser = OptionParser.new do |o|
  o.banner = 'Usage: ./scripts/new_post.rb "Post title" [--tags tag1,tag2] [--slug slug]'
  o.on('--tags LIST', 'Comma-separated tags (PT slugs from data/tag_taxonomy.yml)') do |v|
    options[:tags] = v.split(',').map(&:strip).reject(&:empty?)
  end
  o.on('--slug SLUG', 'Post slug (default: derived from the title)') { |v| options[:slug] = v }
end
parser.parse!

title = ARGV.join(' ').strip
abort parser.banner if title.empty?

require 'json'
slug = slugify(options[:slug] || title)
abort "Could not derive a slug from #{title.inspect}; pass --slug." if slug.empty?

known = pt_tags
unknown = options[:tags] - known
unless unknown.empty?
  abort "Unknown tags: #{unknown.join(', ')}\nAvailable: #{known.join(', ')}\n" \
        'To add a new one, edit data/tag_taxonomy.yml (see TAGGING.md).'
end

now = Time.now
dir = File.join(CONTENT_DIR, now.strftime('%Y/%m/%d'), slug)
file = File.join(dir, 'index.md')
abort "Already exists: #{file}" if File.exist?(file)

Dir.glob(File.join(CONTENT_DIR, '*/*/*', slug)).each do |other|
  warn "Warning: another post already uses this slug: #{other}"
end

require 'fileutils'
FileUtils.mkdir_p(dir)
File.write(file, <<~MD)
  ---
  title: #{yaml_string(title)}
  date: '#{now.strftime('%Y-%m-%dT%H:%M:%S%:z')}'
  description: ""
  tags: [#{options[:tags].join(', ')}]
  draft: true
  ---

MD

puts "Created: #{file}"
puts "URL once published: /#{now.strftime('%Y/%m/%d')}/#{slug}/"
puts
puts 'Next steps:'
puts '  1. Write the post and fill in description and tags'
puts "     Available tags: #{known.join(', ')}" unless known.empty?
puts '  2. Preview locally: hugo server -D   (-D shows drafts)'
puts '  3. To publish: remove the draft: true line, run ./scripts/generate_index.rb, commit and push'
