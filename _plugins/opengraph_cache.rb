require 'json'
require 'open-uri'
require 'openssl'
require 'nokogiri'
require 'uri'

Jekyll::Hooks.register :site, :post_read do |site|
  cache_path = File.join(site.source, '_data', 'og_cache.json')
  cache = File.exist?(cache_path) ? JSON.parse(File.read(cache_path)) : {}

  cutoff = Date.today - 30
  urls_to_fetch = []

  site.posts.docs.each do |post|
    ressources = post.data['ressources']
    next unless ressources.is_a?(Array)

    ressources.each do |r|
      url = r['url']
      next unless url.is_a?(String) && !url.empty?

      entry = cache[url]
      needs_fetch = entry.nil? || (
        !entry['fallback'] &&
        entry['fetched_at'] &&
        Date.parse(entry['fetched_at']) < cutoff rescue true
      )

      urls_to_fetch << url if needs_fetch
    end
  end

  urls_to_fetch.uniq!

  if urls_to_fetch.empty?
    Jekyll.logger.info 'OG Cache:', 'All URLs already cached, nothing to fetch.'
  else
    Jekyll.logger.info 'OG Cache:', "#{urls_to_fetch.size} URL(s) to fetch..."

    urls_to_fetch.each_with_index do |url, i|
      sleep 1 if i > 0

      domain = begin
        URI.parse(url).host.sub(/\Awww\./, '')
      rescue URI::InvalidURIError
        url
      end

      begin
        html = URI.open(
          url,
          'User-Agent' => 'Mozilla/5.0 (compatible; Jekyll OG fetcher)',
          redirect: true,
          open_timeout: 10,
          read_timeout: 15,
          ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
        ).read

        doc = Nokogiri::HTML(html)

        og_title       = doc.at('meta[property="og:title"]')&.[]('content')
        og_description = doc.at('meta[property="og:description"]')&.[]('content')

        # Fallback to <title> and <meta name="description"> if OG tags absent
        title       = og_title       || doc.at('title')&.text&.strip
        description = og_description || doc.at('meta[name="description"]')&.[]('content')

        if title && !title.empty?
          cache[url] = {
            'title'       => title.strip,
            'description' => description&.strip,
            'domain'      => domain,
            'fetched_at'  => Date.today.to_s,
            'fallback'    => false
          }
          Jekyll.logger.info 'OG Cache:', "Fetched: #{url}"
        else
          raise 'No title found'
        end

      rescue => e
        Jekyll.logger.warn 'OG Cache:', "Failed (#{e.class}: #{e.message.lines.first.strip}) — #{url}"
        cache[url] = {
          'domain'     => domain,
          'fetched_at' => Date.today.to_s,
          'fallback'   => true
        }
      end
    end

    File.write(cache_path, JSON.pretty_generate(cache))
    Jekyll.logger.info 'OG Cache:', "Cache saved to #{cache_path}"
  end

  # Inject cache into site data so Liquid can access it via site.data.og_cache
  site.data['og_cache'] = cache
end
