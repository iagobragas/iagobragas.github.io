#!/usr/bin/env ruby
# frozen_string_literal: true

# Creates a new post as a draft: content/YYYY/MM/DD/<slug>/index.md
#
# Usage:
#   ./scripts/new_post.rb "Título do post"
#   ./scripts/new_post.rb "Título do post" --tags programacao,ferramentas
#   ./scripts/new_post.rb "Título do post" --slug outro-endereco
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
  o.banner = 'Uso: ./scripts/new_post.rb "Título do post" [--tags tag1,tag2] [--slug endereco]'
  o.on('--tags LIST', 'Tags separadas por vírgula (slugs em PT de data/tag_taxonomy.yml)') do |v|
    options[:tags] = v.split(',').map(&:strip).reject(&:empty?)
  end
  o.on('--slug SLUG', 'Endereço do post (padrão: gerado a partir do título)') { |v| options[:slug] = v }
end
parser.parse!

title = ARGV.join(' ').strip
abort parser.banner if title.empty?

require 'json'
slug = slugify(options[:slug] || title)
abort "Não foi possível gerar um endereço a partir de #{title.inspect}; use --slug." if slug.empty?

known = pt_tags
unknown = options[:tags] - known
unless unknown.empty?
  abort "Tags desconhecidas: #{unknown.join(', ')}\nDisponíveis: #{known.join(', ')}\n" \
        'Para criar uma nova, adicione em data/tag_taxonomy.yml (veja TAGGING.md).'
end

now = Time.now
dir = File.join(CONTENT_DIR, now.strftime('%Y/%m/%d'), slug)
file = File.join(dir, 'index.md')
abort "Já existe: #{file}" if File.exist?(file)

Dir.glob(File.join(CONTENT_DIR, '*/*/*', slug)).each do |other|
  warn "Aviso: já existe um post com o mesmo endereço final em #{other}"
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

puts "Criado: #{file}"
puts "Endereço quando publicado: /#{now.strftime('%Y/%m/%d')}/#{slug}/"
puts
puts 'Próximos passos:'
puts '  1. Escreva o post e preencha description e tags'
puts "     Tags disponíveis: #{known.join(', ')}" unless known.empty?
puts '  2. Veja localmente: hugo server -D   (o -D mostra rascunhos)'
puts '  3. Para publicar: remova a linha draft: true, rode ./scripts/generate_index.rb, faça commit e push'
