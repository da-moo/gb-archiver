# frozen_string_literal: true

require 'config'
require 'logger'
require_relative 'gb_archiver/gb_api'
require_relative 'gb_archiver/version'

module GbArchiver
  class Error < StandardError; end

  # Consumes the GB API to determine if a livestream is available, then spawns
  # youtube-dl to get the best quality URL. Finally, ffmpeg is executed to
  # capture it to a file.
  class Archiver
    @log = Logger.new(STDOUT)
    FFMPEG_COMMAND = <<~FFMPEG.strip.gsub(/\s+/, ' ')
      ffmpeg
      -m3u8_hold_counters 30
      -i %<url>s
      -c copy
      %<out_dir>s/%<out_file>s
      > log/ffmpeg-%<log>s.log
      2>&1
    FFMPEG
    YOUTUBE_DL_COMMAND = '%<youtube_dl>s --get-url %<url>s'

    def self.main
      Config.load_and_set_settings('config/settings.yml')
      api = GbApi.new(Settings.api_key, @log)
      @log.info('Config loaded, beginning loop...')
      cycle(api)
    end

    def self.cycle(api)
      Kernel.loop do
        video = api.current_live[:video]
        capture(stream_link(video[:stream])) unless video.nil?
        @log.info("Sleeping for #{Settings.api_query_interval} seconds...")
        sleep(Settings.api_query_interval)
      end
    end

    def self.stream_link(m3u8_url)
      full_command = format(YOUTUBE_DL_COMMAND,
                            youtube_dl: Settings.youtube_dl_command,
                            url: m3u8_url)
      @log.info('Running youtube-dl: ' + full_command)
      `#{full_command}`.strip
    end

    def self.capture(url)
      timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
      full_command = format(FFMPEG_COMMAND, url: url,
                                            out_dir: Settings.out_dir,
                                            out_file: "#{timestamp}.ts",
                                            log: timestamp)
      @log.info('Running ffmpeg: ' + full_command)
      `#{full_command}`
    end
  end
end
