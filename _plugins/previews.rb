require 'fileutils'
require 'imgkit'

module Previews
  def self.process(site, payload)
    begin
      FileUtils.mkdir_p('./images/previews')
    rescue
    end

    root     = Dir.pwd
    font_src = "file://#{root}/assets/fonts/UncutSans-Variable.ttf"

    site.collections['posts'].docs.each do |p|
      slug    = p.data['slug']
      src_img = "./images/previews/#{slug}.png"

      post_mtime    = File.mtime(p.path)
      preview_mtime = File.exist?(src_img) ? File.mtime(src_img) : Time.at(0)
      next if preview_mtime >= post_mtime

      puts "\n  Creating preview: #{slug}.png"

      img_src = "file://#{root}#{p.data['image']}"
      title   = p.data['title']
      tags    = p.data['tags-preview']

      kit = IMGKit.new(
        "<!DOCTYPE HTML>
        <html>
          <head>
            <meta charset='utf-8' />
            <style>
              @font-face {
                font-family: 'UncutSans';
                src: url('#{font_src}');
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
              <div class='right-img' style='background-image: url(\"#{img_src}\")'></div>
            </div>
          </body>
        </html>",
        zoom: 2,
        quality: 100,
        width: 1200,
        height: 630,
        :allow => root
      )

      kit.to_file(src_img)

      `pngquant #{src_img} -o #{src_img} -f`
    end
  end
end

Jekyll::Hooks.register :site, :post_render do |site, payload|
  Previews.process(site, payload)
end
