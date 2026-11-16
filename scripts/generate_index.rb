#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'
require 'cgi'

CONTENT_DIR = 'content'
INDEX_FILE = "#{CONTENT_DIR}/_index.md"
INDEX_FILE_EN = "#{CONTENT_DIR}/_index.en.md"
ARCHIVES_DIR = "#{CONTENT_DIR}/archives"
ARCHIVES_FILE = "#{ARCHIVES_DIR}/_index.md"
ARCHIVES_FILE_EN = "#{ARCHIVES_DIR}/_index.en.md"
SITE_TITLE = 'Iago Braga'
FRONTMATTER_DELIMITER = '---'
TAG_TAXONOMY = YAML.safe_load_file('data/tag_taxonomy.yml')
ALLOWED_TAGS = {
  pt: TAG_TAXONOMY.fetch('tags').values.map { |values| values.fetch('pt') } +
      TAG_TAXONOMY.fetch('event_series').keys +
      TAG_TAXONOMY.fetch('special_tags').values.map { |values| values.fetch('pt') },
  en: TAG_TAXONOMY.fetch('tags').values.map { |values| values.fetch('en') } +
      TAG_TAXONOMY.fetch('event_series').keys +
      TAG_TAXONOMY.fetch('special_tags').values.map { |values| values.fetch('en') }
}.transform_values(&:freeze).freeze

# Featured carousel on the homepage: [date, title, url] of published posts.
# Example: ['2026-11-15', 'Olá, mundo', '/2026/11/15/ola-mundo/']
FEATURED_POSTS = [
].freeze

FEATURED_POSTS_EN = [
].freeze

# Archive page (/archives/): off while the blog is small, so the homepage lists every post.
# When enabled, the homepage shows posts from January of last year onward and older ones
# move to /archives/ (also re-add the "Arquivo"/"Archives" links in navbar, footer and hugo.yaml menus).
ARCHIVE_ENABLED = false
CUTOFF_YEAR = Date.today.year - 1

def escape_markdown(text)
  text.to_s.gsub('[', '\\[').gsub(']', '\\]')
end

def escape_html(text)
  CGI.escapeHTML(text.to_s)
end

def tag_url(tag, lang: :pt)
  prefix = lang == :en ? '/en' : ''
  "#{prefix}/tags/#{CGI.escape(tag).gsub('+', '%20')}/"
end

def render_tag_links(tags, lang:, modifier:)
  links = tags.map do |tag|
    %(<a class="aor-tag-link" href="#{escape_html(tag_url(tag, lang: lang))}">##{escape_html(tag)}</a>)
  end
  return '' if links.empty?

  %(<span class="aor-post-tags aor-post-tags--#{modifier}">#{links.join}</span>)
end

def extract_frontmatter(content)
  return nil unless content.start_with?("#{FRONTMATTER_DELIMITER}\n")

  end_index = content.index("\n#{FRONTMATTER_DELIMITER}\n", 4)
  return nil unless end_index

  yaml_content = content[4..end_index]
  YAML.safe_load(yaml_content, permitted_classes: [Date, Time])
end

def parse_post(path, lang: :pt, include_drafts: false)
  content = File.read(path)
  frontmatter = extract_frontmatter(content)
  return nil unless frontmatter&.dig('title') && frontmatter&.dig('date')
  return nil if frontmatter['draft'] == true && !include_drafts

  date = DateTime.parse(frontmatter['date'].to_s)
  base_path = path.sub(%r{/index(\.en)?\.md\z}, '')
  dir_url = base_path.delete_prefix("#{CONTENT_DIR}/") # e.g. 2026/04/06/rag-esta-morto-contexto-longo

  # Honor a `slug:` frontmatter override (used by EN translations to get a
  # translated URL while keeping the original PT directory name on disk).
  if frontmatter['slug'] && !frontmatter['slug'].to_s.empty?
    slug = frontmatter['slug'].to_s
    parts = dir_url.split('/')
    parts[-1] = slug
    dir_url = parts.join('/')
  end

  url = '/' + dir_url + '/'
  url = '/en' + url if lang == :en

  has_en = File.exist?("#{base_path}/index.en.md")
  tags = Array(frontmatter['tags']).map(&:to_s)
  unknown_tags = tags - ALLOWED_TAGS.fetch(lang)
  unless unknown_tags.empty?
    raise "#{path}: unknown #{lang.to_s.upcase} tag(s): #{unknown_tags.join(', ')}. Run scripts/tag_catalog.rb --search QUERY."
  end

  {
    title: frontmatter['title'],
    description: frontmatter['description'].to_s,
    url: url,
    date: date,
    has_en: has_en,
    lang: lang,
    tags: tags
  }
rescue ArgumentError, Psych::SyntaxError => e
  warn "Error parsing #{path}: #{e.message}"
  nil
end

def collect_posts(include_future: false, include_drafts: false)
  now = DateTime.now
  Dir.glob("#{CONTENT_DIR}/**/index.md")
     .reject { |path| path == "#{CONTENT_DIR}/index.md" || path == "#{CONTENT_DIR}/_index.md" }
     .reject { |path| path.start_with?("#{ARCHIVES_DIR}/") }
     .filter_map { |path| parse_post(path, lang: :pt, include_drafts: include_drafts) }
     .select { |post| include_future || post[:date] <= now }
end

def collect_posts_en(include_future: false, include_drafts: false)
  now = DateTime.now
  Dir.glob("#{CONTENT_DIR}/**/index.en.md")
     .reject { |path| path.start_with?("#{ARCHIVES_DIR}/") }
     .filter_map { |path| parse_post(path, lang: :en, include_drafts: include_drafts) }
     .select { |post| include_future || post[:date] <= now }
end

def group_by_month(posts)
  posts
    .sort_by { |post| post[:date] }
    .reverse
    .group_by { |post| [post[:date].year, post[:date].month] }
end

PT_MONTHNAMES = [nil, 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'].freeze

def render_months(grouped_posts, lang: :pt, show_tags: false)
  sorted_months = grouped_posts.keys.sort.reverse
  lines = []

  sorted_months.each do |(year, month)|
    month_name = lang == :pt ? PT_MONTHNAMES[month] : Date::MONTHNAMES[month]
    posts = grouped_posts[[year, month]]
    count_word = if lang == :pt
                   posts.length == 1 ? 'artigo' : 'artigos'
                 else
                   posts.length == 1 ? 'article' : 'articles'
                 end
    heading_id = "aor-list-#{year}-#{format('%02d', month)}"
    lines << <<~HTML.chomp
      <section class="aor-index-month" aria-labelledby="#{heading_id}">
        <div class="aor-index-month__header">
          <h2 id="#{heading_id}">#{escape_html("#{month_name} #{year}")}</h2>
          <span>#{posts.length} #{count_word}</span>
        </div>
        <div class="aor-index-list-group">
    HTML

    posts.each do |post|
      date_label = post[:date].strftime('%b %d')
      tags = show_tags ? render_tag_links(post[:tags], lang: lang, modifier: 'index-list') : ''
      lines << <<~HTML.chomp
        <article class="aor-index-row" title="#{escape_html(post[:description])}">
          <time datetime="#{post[:date].to_date.iso8601}">#{escape_html(date_label)}</time>
          <div class="aor-index-row__body">
            <h3><a class="aor-index-list__main-link" href="#{escape_html(post[:url])}">#{escape_html(post[:title])}</a></h3>
            <p>#{escape_html(post[:description])}</p>
          </div>
          #{tags}
        </article>
      HTML
    end

    lines << '  </div>'
    lines << '</section>'
    lines << ''
  end

  lines
end

def render_post_card(post, lang: :pt)
  date_label = if lang == :pt
                 post[:date].strftime('%d/%m/%Y')
               else
                 post[:date].strftime('%b %-d, %Y')
               end

  <<~HTML.chomp
    <article class="aor-post-card" title="#{escape_html(post[:description])}">
      <time class="aor-post-card__date" datetime="#{post[:date].to_date.iso8601}">#{escape_html(date_label)}</time>
      <h3 class="aor-post-card__title"><a class="aor-post-card__title-link" href="#{escape_html(post[:url])}">#{escape_html(post[:title])}</a></h3>
      #{render_tag_links(post[:tags], lang: lang, modifier: 'card')}
      <p class="aor-post-card__description">#{escape_html(post[:description])}</p>
    </article>
  HTML
end

def render_grid_months(grouped_posts, lang: :pt)
  sorted_months = grouped_posts.keys.sort.reverse
  lines = ['<div id="aor-index-grid" class="aor-index-grid" data-index-view="grid">']

  sorted_months.each do |(year, month)|
    month_name = lang == :pt ? PT_MONTHNAMES[month] : Date::MONTHNAMES[month]
    posts = grouped_posts[[year, month]]
    count_label = "#{posts.length} #{posts.length == 1 ? 'post' : 'posts'}"
    heading_id = "aor-grid-#{year}-#{format('%02d', month)}"

    lines << <<~HTML.chomp
      <section class="aor-index-month" aria-labelledby="#{heading_id}">
        <div class="aor-index-month__header">
          <h2 id="#{heading_id}">#{escape_html("#{year} - #{month_name}")}</h2>
          <span>#{escape_html(count_label)}</span>
        </div>
        <div class="aor-post-grid">
    HTML

    posts.each { |post| lines << render_post_card(post, lang: lang) }

    lines << <<~HTML.chomp
        </div>
      </section>
    HTML
  end

  lines << '</div>'
  lines << ''
  lines
end

def index_view_labels(lang)
  if lang == :pt
    { list: 'Lista', grid: 'Grade', group: 'Visualização dos posts' }
  else
    { list: 'List', grid: 'Grid', group: 'Post view' }
  end
end

def render_index_view_toggle(lang: :pt)
  labels = index_view_labels(lang)

  [
    %({{< index-view-toggle list="#{labels[:list]}" grid="#{labels[:grid]}" label="#{labels[:group]}" >}}),
    ''
  ]
end

def render_index_views(grouped_posts, lang: :pt)
  lines = []

  lines << '{{% index-list %}}'
  lines.concat(render_months(grouped_posts, lang: lang, show_tags: true))
  lines << '{{% /index-list %}}'
  lines
end

def render_featured_posts(grouped_posts)
  render_featured_section(
    id: 'aor-featured-posts',
    title: 'Destaques',
    button_open: 'Esconder',
    button_closed: 'Mostrar',
    posts: FEATURED_POSTS,
    available_posts: grouped_posts.values.flatten,
    lang: :pt
  )
end

def render_featured_posts_en(grouped_posts)
  render_featured_section(
    id: 'aor-featured-posts-en',
    title: 'Featured',
    button_open: 'Hide',
    button_closed: 'Show',
    posts: FEATURED_POSTS_EN,
    available_posts: grouped_posts.values.flatten,
    lang: :en
  )
end

def render_featured_section(id:, title:, button_open:, button_closed:, posts:, available_posts:, lang:)
  lines = []
  post_lookup = available_posts.to_h { |post| [post[:url], post] }
  featured = posts.filter_map { |_date, _post_title, url| post_lookup[url] }
  total = featured.length
  return lines if total.zero?
  visible = [3, total].min
  counter = lang == :pt ? "1–#{visible} de #{total}" : "1–#{visible} of #{total}"

  lines << <<~HTML.chomp
    <section id="#{id}" class="aor-featured" data-featured-carousel data-featured-lang="#{lang}">
      <div class="aor-featured__header">
        <h2>#{title}</h2>
        <div class="aor-featured__controls">
          <span class="aor-featured__counter" aria-live="polite">#{counter}</span>
          <div class="aor-featured__buttons">
            <button type="button" data-featured-prev aria-label="#{lang == :pt ? 'Destaques anteriores' : 'Previous featured posts'}">&#8249;</button>
            <button type="button" data-featured-next aria-label="#{lang == :pt ? 'Próximos destaques' : 'Next featured posts'}">&#8250;</button>
          </div>
        </div>
      </div>
      <div class="aor-featured__track">
  HTML

  featured.each_with_index do |post, index|
    date_label = post[:date].strftime('%b %d, %Y')
    lines << <<~HTML.chomp
      <article class="aor-featured-card" data-featured-item data-featured-index="#{index}">
        <time datetime="#{post[:date].to_date.iso8601}">#{escape_html(date_label)}</time>
        <h3><a href="#{escape_html(post[:url])}">#{escape_html(post[:title])}</a></h3>
        <p>#{escape_html(post[:description])}</p>
        #{render_tag_links(post[:tags], lang: lang, modifier: 'featured-card')}
      </article>
    HTML
  end

  lines << <<~HTML.chomp
      </div>
    </section>
  HTML

  lines << ''
  lines
end

def generate_index(grouped_posts)
  lines = ["#{FRONTMATTER_DELIMITER}\ntitle: #{SITE_TITLE}\n#{FRONTMATTER_DELIMITER}\n"]
  if grouped_posts.empty?
    lines << '<p class="aor-listing-intro"><em>Em construção. Os posts aparecem aqui em breve.</em></p>'
  else
    lines.concat(render_featured_posts(grouped_posts))
    lines << '<div class="aor-recent-header">'
    lines << "<h2>#{ARCHIVE_ENABLED ? 'Artigos recentes' : 'Artigos'}</h2>"
    lines.concat(render_index_view_toggle(lang: :pt))
    lines << '</div>'
    lines.concat(render_index_views(grouped_posts, lang: :pt))
  end
  lines << '<div class="aor-archive-link"><a href="/archives/">Ver arquivo completo →</a></div>' if ARCHIVE_ENABLED
  lines.join("\n")
end

def generate_archives(grouped_posts)
  lines = ["#{FRONTMATTER_DELIMITER}\ntitle: Arquivo\n#{FRONTMATTER_DELIMITER}\n"]
  lines << "<p class=\"aor-listing-intro\">Posts anteriores a #{CUTOFF_YEAR}.</p>"
  if grouped_posts.empty?
    lines << '<p class="aor-listing-intro"><em>Nenhum post antigo ainda.</em></p>'
  else
    lines.concat(render_index_views(grouped_posts, lang: :pt))
  end
  lines.join("\n")
end

def generate_index_en(grouped_posts)
  lines = ["#{FRONTMATTER_DELIMITER}\ntitle: #{SITE_TITLE}\n#{FRONTMATTER_DELIMITER}\n"]
  if grouped_posts.empty?
    lines << '<p class="aor-listing-intro"><em>No posts in English yet. Check back soon.</em></p>'
  else
    lines.concat(render_featured_posts_en(grouped_posts))
    lines << '<div class="aor-recent-header">'
    lines << "<h2>#{ARCHIVE_ENABLED ? 'Recent articles' : 'Articles'}</h2>"
    lines.concat(render_index_view_toggle(lang: :en))
    lines << '</div>'
    lines.concat(render_index_views(grouped_posts, lang: :en))
  end
  lines << '<div class="aor-archive-link"><a href="/en/archives/">Browse the full archive →</a></div>' if ARCHIVE_ENABLED
  lines.join("\n")
end

def generate_archives_en(grouped_posts)
  lines = ["#{FRONTMATTER_DELIMITER}\ntitle: Archives\n#{FRONTMATTER_DELIMITER}\n"]
  lines << "<p class=\"aor-listing-intro\">Posts before #{CUTOFF_YEAR}.</p>"
  if grouped_posts.empty?
    lines << '<p class="aor-listing-intro"><em>No older posts in English yet.</em></p>'
  else
    lines.concat(render_index_views(grouped_posts, lang: :en))
  end
  lines.join("\n")
end

include_future = ARGV.include?('--future')
include_drafts = ARGV.include?('--drafts')
suffix_parts = []
suffix_parts << 'future posts' if include_future
suffix_parts << 'drafts' if include_drafts
suffix = suffix_parts.empty? ? '' : " (including #{suffix_parts.join(' + ')})"

if include_drafts || include_future
  flags = []
  flags << '--drafts' if include_drafts
  flags << '--future' if include_future
  verb = flags.one? ? 'is a' : 'are'
  noun = flags.one? ? 'flag' : 'flags'
  warn "*** #{flags.join(' and ')} #{verb} local preview #{noun} only. Unpublished posts will"
  warn '*** appear in the generated _index.md files below. Do NOT commit these files'
  warn "*** while #{flags.join('/')} is on — re-run this script WITHOUT them before"
  warn '*** committing, or you will leak unpublished posts (title, URL, description)'
  warn '*** onto the live homepage/archive.'
end

posts = collect_posts(include_future: include_future, include_drafts: include_drafts)
grouped = group_by_month(posts)

recent = ARCHIVE_ENABLED ? grouped.select { |(year, _month), _| year >= CUTOFF_YEAR } : grouped
archived = grouped.select { |(year, _month), _| year < CUTOFF_YEAR }

File.write(INDEX_FILE, generate_index(recent))
recent_count = recent.values.flatten.size
puts "Generated #{INDEX_FILE} with #{recent_count} posts.#{suffix}"

if ARCHIVE_ENABLED
  Dir.mkdir(ARCHIVES_DIR) unless Dir.exist?(ARCHIVES_DIR)
  File.write(ARCHIVES_FILE, generate_archives(archived))
  puts "Generated #{ARCHIVES_FILE} with #{archived.values.flatten.size} posts (before #{CUTOFF_YEAR}).#{suffix}"
end

# English index — only posts with index.en.md siblings
posts_en = collect_posts_en(include_future: include_future, include_drafts: include_drafts)
grouped_en = group_by_month(posts_en)
recent_en = ARCHIVE_ENABLED ? grouped_en.select { |(year, _month), _| year >= CUTOFF_YEAR } : grouped_en

File.write(INDEX_FILE_EN, generate_index_en(recent_en))
recent_en_count = recent_en.values.flatten.size
puts "Generated #{INDEX_FILE_EN} with #{recent_en_count} posts.#{suffix}"

if ARCHIVE_ENABLED
  archived_en = grouped_en.select { |(year, _month), _| year < CUTOFF_YEAR }
  File.write(ARCHIVES_FILE_EN, generate_archives_en(archived_en))
  puts "Generated #{ARCHIVES_FILE_EN} with #{archived_en.values.flatten.size} posts (before #{CUTOFF_YEAR}).#{suffix}"
end


if include_drafts || include_future
  warn ''
  warn "*** Reminder: #{(ARCHIVE_ENABLED ? [INDEX_FILE, ARCHIVES_FILE, INDEX_FILE_EN, ARCHIVES_FILE_EN] : [INDEX_FILE, INDEX_FILE_EN]).join(', ')}"
  warn '*** were just regenerated WITH unpublished posts. Re-run without the preview'
  warn '*** flags before committing.'
end
