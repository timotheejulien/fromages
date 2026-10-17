require 'fileutils'
require 'json'
require 'open3'

module Previews
  def self.process(site, payload)
    root        = site.source
    preview_dir = File.join(root, 'images', 'previews')
    FileUtils.mkdir_p(preview_dir)

    font_path = File.join(root, 'assets', 'fonts', 'UncutSans-Variable.ttf')
    renderer  = File.join(root, 'scripts', 'render_previews.mjs')
    source_mtime = [File.mtime(__FILE__), File.mtime(renderer)].max

    previews = []

    site.collections['posts'].docs.each do |p|
      slug    = p.data['slug']
      src_img = File.join(preview_dir, "#{slug}.png")

      post_mtime    = [File.mtime(p.path), source_mtime].max
      preview_mtime = File.exist?(src_img) ? File.mtime(src_img) : Time.at(0)
      next if preview_mtime >= post_mtime

      puts "\n  Creating preview: #{slug}.png"

      image_path = File.join(root, p.data['image'].sub(%r{\A/}, ''))
      title   = p.data['title']
      tags    = p.data['tags-preview']

      previews << {
        path: src_img,
        font_path: font_path,
        image_path: image_path,
        html: <<~HTML
        <!DOCTYPE HTML>
        <html>
          <head>
            <meta charset='utf-8' />
            <style>
              @font-face {
                font-family: 'UncutSans';
                src: url('__FONT_SRC__') format('truetype');
                font-style: normal;
                font-weight: 100 900;
              }

              * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
              }

              body {
                width: 600px;
                height: 315px;
                display: table;
                background: #FBFBFB;
                font-family: 'UncutSans', sans-serif;
                overflow: hidden;
              }

              .left {
                display: table-cell;
                vertical-align: top;
              }

              .left-inner {
                position: relative;
                width: 300px;
                height: 315px;
              }

              .site-label {
                position: absolute;
                top: 24px;
                left: 24px;
                font-size: 14px;
                font-weight: 400;
                color: #707070;
              }

              .title {
                position: absolute;
                bottom: 48px;
                left: 24px;
                right: 16px;
                font-size: 2.4rem;
                font-weight: 400;
                line-height: 1.1;
                color: #202020;
              }

              .tags {
                position: absolute;
                bottom: 24px;
                left: 24px;
                font-size: 14px;
                font-weight: 400;
                color: #707070;
              }

              .right {
                display: table-cell;
                vertical-align: top;
                width: 300px;
                padding: 24px 24px 24px 0;
              }

              .right-img {
                width: 100%;
                height: 267px;
                border-radius: 8px;
                background-size: cover;
                background-position: center;
              }
            </style>
          </head>
          <body>
            <div class='left'>
              <div class='left-inner'>
                <p class='site-label'>Notes fromagères</p>
                <h2 class='title'>#{title}</h2>
                <p class='tags'>#{tags}</p>
              </div>
            </div>
            <div class='right'>
              <div class='right-img' style='background-image: url(\"__IMAGE_SRC__\")'></div>
            </div>
          </body>
        </html>
        HTML
      }
    end

    return if previews.empty?

    _output, error, status = Open3.capture3('node', renderer, stdin_data: JSON.generate(previews))
    raise "Impossible de générer les previews : #{error}" unless status.success?
  end
end

Jekyll::Hooks.register :site, :post_render do |site, payload|
  Previews.process(site, payload)
end
